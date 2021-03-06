package ISC::BIND::Stats::Parser;
use common::sense;
use base qw(XML::SAX::Base);
use Data::Dumper;

my $element_stack         = [];
my $current_view          = q{};
my $current_zone          = q{};
my $cluster_counters      = {};
my $current_query_counter = q{};
my $valid_zone            = 0;
my $current_opcode        = q{};
my $current_class         = q{};
my $current_nsstat        = q{};
my $current_zonestat      = q{};

my $counter_name  = undef;

sub start_element {
  my ( $self, $el ) = @_;

  if($el->{Name} eq 'isc') {
      $self->{isc_version}   = $el->{Attributes}->{'{}version'}->{'Value'};
  }
  if($el->{Name} eq 'statistics') {
      $self->{stats_version} = $el->{Attributes}->{'{}version'}->{'Value'};
      if($self->{stats_version} =~ /2\.\d+/) {
	  $self->optprint("founding v2 stats file");
          $self->{v2stats} = 1;
      }
      if($self->{stats_version} =~ /3\.\d+/) {
	  $self->optprint("founding ".${self}->{stats_version}." stats file");
          $self->{v3stats} = 1;
      }
  }

  #print Dumper($self);
  # process element start event
  push @$element_stack, $el;

}

sub end_element {
  my ( $self, $el ) = @_;

  if ( $el->{Name} eq 'counters' ) {
    $valid_zone = 0;
  }

  pop @$element_stack;
}

sub optprint {
    my $self = shift;

    if($self->{bind9statsdebug}) {
        my $fmt = shift;
        print sprintf($fmt, @_);
    }
}
sub get_attribute {
    my $self    = shift;
    my($element,$name) = @_;

    my $curlyname="{}".$name;

    return $element->{Attributes}->{$curlyname}->{Value};
}
sub get_name {
    my $self    = shift;
    my($element) = @_;
    return $self->get_attribute($element, "name");
}

sub get_namelc {
    my $self    = shift;
    my($element) = @_;
    return lc $self->get_name($element);
}

sub get_type {
    my $self    = shift;
    my($element) = @_;
    return lc $self->get_attribute($element, "type");
}

sub get_typelc {
    my $self    = shift;
    my($element) = @_;
    return lc $self->get_type($element);
}

sub characters {
  my ( $self, $data ) = @_;

  # do this with log4perl?
  $self->optprint("in item[%u]: %s\n", scalar @{$element_stack}, join(' ', map { lc $_->{Name} } @{$element_stack}));

  my $element1 = $element_stack->[-1];
  my $element2 = $element_stack->[-2];
  my $element_name1 = lc $element1->{Name};
  my $element_name2 = lc $element2->{Name};

  # this is the same between v2/v3
  if ( $element_name2 eq 'server' ) {
    if ( $element_name1 eq 'boot-time' ) {
      $self->{boot_time} = $data->{Data};
      return;
    }
    if ( $element_name1 eq 'current-time' ) {
      $self->{sample_time} = $data->{Data};
      return;
    }
  }

  if($self->{v2stats}) {
      return $self->characters_v2($data);
  } elsif($self->{v3stats}) {
      return $self->characters_v3($data);
  } else {
      warn("Invalid stats version");
      return;
  }

}

sub characters_v2 {
  my ( $self, $data ) = @_;

  my $element1 = $element_stack->[-1];
  my $element2 = $element_stack->[-2];
  my $element3 = $element_stack->[-3];
  my $element4 = $element_stack->[-4];
  my $element5 = $element_stack->[-5];

  my $element_name1 = lc $element1->{Name};
  my $element_name2 = lc $element2->{Name};
  my $element_name3 = lc $element3->{Name};
  my $element_name4 = lc $element4->{Name};
  my $element_name5 = lc $element5->{Name};

  if ( $element_name1 eq 'name' && $element_name2 eq 'view' ) {
    $current_view = $data->{Data};
    return;
  }

  if ( $element_name1 eq 'name' && $element_name2 eq 'zone' ) {
    $current_zone = $data->{Data};
    $current_zone =~ s|/IN$||;
    return;
  }

  if ( $element_name1 eq 'serial'
       && $data->{Data} > 0 )
  {
    $valid_zone = 1;
    $self->{zone}->{$current_zone}->{serial} = $data->{Data};
    return;
  }
  if ( $element_name2 eq 'counters' ) {
      if ($valid_zone) {
      $self->{zone}->{$current_zone}->{counters}->{ $element_name1 } = $data->{Data};
      return;
    }
  }

  # for v2 rdtype
  if ( $element_name4 eq 'server'
       && $element_name3 eq 'queries-in' )
  {
    if ( $element_name2 eq 'rdtype' ) {
      if ( $element_name1 eq 'name' ) {
        $current_query_counter = $data->{Data};
        return;
      }
      if ( $element_name1 eq 'counter' ) {
        $self->{server}->{requests}->{rdtype}->{$current_query_counter} = $data->{Data};
        return;
      }
    }
  }

  # for v2 opcode counters
  if ( $element_name3 eq 'requests' ) {
    if ( $element_name2 eq 'opcode' ) {
      if ( $element_name1 eq 'name' ) {
        $current_opcode = $data->{Data};
        return;
      }
      else {
        $self->{server}->{requests}->{opcode}->{$current_opcode} = $data->{Data};
        return;
      }
    }
  }
  if ( $element_name3 eq 'server' ) {
    if (    $element_name1 eq 'name'
         && $element_name2 eq 'nsstat' )
    {
      $current_nsstat = $data->{Data};
      return;
    }
    if (    $element_name1 eq 'counter'
         && $element_name2 eq 'nsstat' )
    {
      $self->{server}->{requests}->{nsstat}->{$current_nsstat} = $data->{Data};
      return;
    }

    if ( $element_name1 eq 'name' && $element_name2 eq 'zonestat' ) {
      $current_zonestat = $data->{Data};
      return;
    }
    if ( $element_name1 eq 'counter' && $element_name2 eq 'zonestat' ) {
      $self->{server}->{requests}->{zonestat}->{$current_zonestat} = $data->{Data};
      return;
    }
  }
}

sub characters_v3 {
  my ( $self, $data ) = @_;

  my $element1 = $element_stack->[-1];
  my $element2 = $element_stack->[-2];
  my $element3 = $element_stack->[-3];
  my $element4 = $element_stack->[-4];
  my $element5 = $element_stack->[-5];

  my $element_name1 = lc $element1->{Name};
  my $element_name2 = lc $element2->{Name};
  my $element_name3 = lc $element3->{Name};
  my $element_name4 = lc $element4->{Name};
  my $element_name5 = lc $element5->{Name};

  # process serial number
  if ($element_name1 eq 'serial'
      && $element_name2 eq 'zone'
      && $element_name3 eq 'zones'
      && $element_name4 eq 'view') {
      #print STDERR Dumper($element_stack);
      $current_view = $self->get_name($element4);
      $current_zone = $self->get_name($element2);
      $current_class= $self->get_attribute($element2, "rdataclass");
      $self->{zone}->{$current_zone}->{serial} = $data->{Data};

      # $self->optprint("adding serial data for zone: %s", $current_zone);
      return;
  }

  # process counter
  if (   $element_name1 eq 'counter'
      && $element_name2 eq 'counters'
      && $element_name3 eq 'zone'
      && $element_name4 eq 'zones'
      && $element_name5 eq 'view') {
      $current_view = $self->get_name($element5);
      $current_zone = $self->get_name($element3);
      $current_class= $self->get_attribute($element3, "rdataclass");
      $counter_name = lc $self->get_name($element1);
      $self->{zone}->{$current_zone}->{counters}->{$counter_name} = $data->{Data};
      return;
  }

  # could just take all counter categories.
  # for v3 opcode counters
  if (   $element_name1 eq 'counter'
      && $element_name2 eq 'counters'
      && $element_name3 eq 'server'
      && $self->get_typelc($element2) eq 'opcode') {
      my $counter_name = $self->get_name($element1);
      $self->{server}->{requests}->{opcode}->{$counter_name} = $data->{Data};
      return;
  }

  # for v3 rdtype counters
  if (   $element_name1 eq 'counter'
      && $element_name2 eq 'counters'
      && $element_name3 eq 'server'
      && $self->get_typelc($element2) eq 'qtype') {

      my $counter_name = $self->get_name($element1);
      $self->{server}->{requests}->{rdtype}->{$counter_name} = $data->{Data};
      return;
  }

  # for v3 rdtype counters
  if (   $element_name1 eq 'counter'
      && $element_name2 eq 'counters'
      && $element_name3 eq 'server'
      && $self->get_typelc($element2) eq 'zonestat') {

      my $counter_name = $self->get_name($element1);
      $self->{server}->{requests}->{zonestat}->{$counter_name} = $data->{Data};
      return;
  }

  # for v3 sockstat counters
  if (   $element_name1 eq 'counter'
      && $element_name2 eq 'counters'
      && $element_name3 eq 'server'
      && $self->get_typelc($element2) eq 'sockstat') {

      my $counter_name = $self->get_name($element1);
      $self->{server}->{requests}->{sockstat}->{$counter_name} = $data->{Data};
      return;
  }



}

sub end_document {
  my ( $self ) = @_;
  return {
      isc_version   => $self->{isc_version},
      stats_version => $self->{stats_version},
      zone            => $self->{zone},
      sample_time     => $self->{sample_time},
      boot_time       => $self->{boot_time},
      server_counters => $self->{server}
  };

}

1;
