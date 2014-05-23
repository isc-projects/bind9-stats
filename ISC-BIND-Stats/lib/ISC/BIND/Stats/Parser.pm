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
my $current_nsstat        = q{};
my $current_zonestat      = q{};

my $boot_time;
my $sample_time;

my $zone = {};

my $server = {};
my $isc_version = undef;
my $stats_version = undef;
my $counter_name  = undef;

sub start_element {
  my ( $self, $el ) = @_;

  if($el->{Name} eq 'isc') {
      $isc_version   = $el->{Attributes}->{'{}version'}->{'Value'};
  }
  if($el->{Name} eq 'statistics') {
      $stats_version = $el->{Attributes}->{'{}version'}->{'Value'};
  }

  if($el->{Name} eq 'counter') {
      $counter_name = $el->{Attributes}->{'name'}->{'Value'};
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

sub characters {
  my ( $self, $data ) = @_;

  # do this with log4perl?
  if($self->{bind9statsdebug}) {
      print sprintf("in item[%u]: %s\n", scalar @{$element_stack}, join(' ', map { lc $_->{Name} } @{$element_stack}));
  }

  my $element_name1 = lc $element_stack->[-1]->{Name};
  my $element_name2 = lc $element_stack->[-2]->{Name};
  my $element_name3 = lc $element_stack->[-3]->{Name};
  my $element_name4 = lc $element_stack->[-4]->{Name};

  if ( $element_name1 eq 'name' && $element_name2 eq 'view' ) {
    $current_view = $data->{Data};
    return;
  }

  if ( $element_name1 eq 'name' && $element_name2 eq 'zone' ) {
    $current_zone = $data->{Data};
    $current_zone =~ s|/IN$||;
    return;
  }

  if (    $element_name1 eq 'serial'
       && $data->{Data} > 0 )
  {
    $valid_zone = 1;
    $zone->{$current_zone}->{serial} = $data->{Data};
    return;
  }
  if ( $element_name2 eq 'counters' ) {
    if ($valid_zone) {
      $zone->{$current_zone}->{counters}->{ $element_name1 } = $data->{Data};
      return;
    }
  }

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

  if (    $element_name4 eq 'server'
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

  if ( $element_name3 eq 'requests' ) {
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
