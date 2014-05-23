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

my $boot_time;
my $sample_time;

my $zone = {};

my $server = {};
my $isc_version = undef;
my $stats_version = undef;
my $counter_name  = undef;
my $v2stats = undef;
my $v3stats = undef;

sub start_element {
  my ( $self, $el ) = @_;

  if($el->{Name} eq 'isc') {
      $isc_version   = $el->{Attributes}->{'{}version'}->{'Value'};
  }
  if($el->{Name} eq 'statistics') {
      $stats_version = $el->{Attributes}->{'{}version'}->{'Value'};
      if($stats_version =~ /2\.\d+/) {
          $v2stats = 1;
      }
      if($stats_version =~ /3\.\d+/) {
          $v3stats = 1;
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
    return lc $self->get_attribute($element, "name");
}

sub get_namelc {
    my $self    = shift;
    my($element) = @_;
    return lc $self->get_name($element);
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
      $boot_time = $data->{Data};
      return;
    }
    if ( $element_name1 eq 'current-time' ) {
      $sample_time = $data->{Data};
      return;
    }
  }

  if($v2stats) {
      return $self->characters_v2($data);
  }

  if($v3stats) {
      return $self->characters_v3($data);
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

  if ( $v2stats && $element_name1 eq 'name' && $element_name2 eq 'view' ) {
    $current_view = $data->{Data};
    return;
  }

  if ( $v2stats && $element_name1 eq 'name' && $element_name2 eq 'zone' ) {
    $current_zone = $data->{Data};
    $current_zone =~ s|/IN$||;
    return;
  }

  if ( $v2stats &&  $element_name1 eq 'serial'
       && $data->{Data} > 0 )
  {
    $valid_zone = 1;
    $zone->{$current_zone}->{serial} = $data->{Data};
    return;
  }
  if ( $v2stats && $element_name2 eq 'counters' ) {
    if ($valid_zone) {
      $zone->{$current_zone}->{counters}->{ $element_name1 } = $data->{Data};
      return;
    }
  }

  # for v2 rdtype
  if ( $v2stats && $element_name4 eq 'server'
       && $element_name3 eq 'queries-in' )
  {
    if ( $element_name2 eq 'rdtype' ) {
      if ( $element_name1 eq 'name' ) {
        $current_query_counter = $data->{Data};
        return;
      }
      if ( $element_name1 eq 'counter' ) {
        $server->{requests}->{rdtype}->{$current_query_counter} = $data->{Data};
        return;
      }
    }
  }

  # for v2 opcode counters
  if ( $v2stats && $element_name3 eq 'requests' ) {
    if ( $element_name2 eq 'opcode' ) {
      if ( $element_name1 eq 'name' ) {
        $current_opcode = $data->{Data};
        return;
      }
      else {
        $server->{requests}->{opcode}->{$current_opcode} = $data->{Data};
        return;
      }
    }
  }
  if ( $v2stats && $element_name3 eq 'server' ) {
    if (    $element_name1 eq 'name'
         && $element_name2 eq 'nsstat' )
    {
      $current_nsstat = $data->{Data};
      return;
    }
    if (    $element_name1 eq 'counter'
         && $element_name2 eq 'nsstat' )
    {
      $server->{requests}->{nsstat}->{$current_nsstat} = $data->{Data};
      return;
    }

    if ( $element_name1 eq 'name' && $element_name2 eq 'zonestat' ) {
      $current_zonestat = $data->{Data};
      return;
    }
    if ( $element_name1 eq 'counter' && $element_name2 eq 'zonestat' ) {
      $server->{requests}->{zonestat}->{$current_zonestat} = $data->{Data};
      return;
    }
  }
}

sub characters_v3 {
  my ( $self, $data ) = @_;

  # do this with log4perl?
  $self->optprint("in item[%u]: %s\n", scalar @{$element_stack}, join(' ', map { lc $_->{Name} } @{$element_stack}));

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
  if ( $v3stats && $element_name1 eq 'serial'
      && $element_name2 eq 'zone'
      && $element_name3 eq 'zones'
      && $element_name4 eq 'view') {
      #print STDERR Dumper($element_stack);
      $current_view = $self->get_name($element4);
      $current_zone = $self->get_name($element2);
      $current_class= $self->get_attribute($element2, "rdataclass");
      $zone->{$current_zone}->{serial} = $data->{Data};

      # $self->optprint("adding serial data for zone: %s", $current_zone);
      return;
  }

  # process counter
  if ( $v3stats && $element_name1 eq 'counter'
      && $element_name2 eq 'counters'
      && $element_name3 eq 'zone'
      && $element_name4 eq 'zones'
      && $element_name5 eq 'view') {
      $current_view = $self->get_name($element5);
      $current_zone = $self->get_name($element3);
      $current_class= $self->get_attribute($element3, "rdataclass");
      $counter_name = $self->get_name($element1);
      $zone->{$current_zone}->{counters}->{$counter_name} = $data->{Data};
      return;
  }

  # for v3 opcode counters
  if ( $v3stats && $element_name1 eq 'counter' &&
      $element_name2 eq 'counters' &&
      $self->get_namelc($element2) eq 'opcode' &&
      $element_name3 eq 'server') {

      my $counter_name = $element1->{Attributes}->{name}->{Value};
      $server->{requests}->{opcode}->{$counter_name} = $data->{Data};
      return;
  }

  # for v3 rdtype counters
  if ( $v3stats && $element_name1 eq 'counter' &&
      $element_name2 eq 'counters' &&
      (lc $element2->{Attributes}->{name}->{Value}) eq 'qtype' &&
      $element_name3 eq 'server') {

      my $counter_name = $element1->{Attributes}->{name}->{Value};
      $server->{requests}->{rdtype}->{$counter_name} = $data->{Data};
      return;
  }



}

sub end_document {
  return {
      isc_version   => $isc_version,
      stats_version => $stats_version,
           zone            => $zone,
           sample_time     => $sample_time,
           boot_time       => $boot_time,
           server_counters => $server
  };

}

1;
