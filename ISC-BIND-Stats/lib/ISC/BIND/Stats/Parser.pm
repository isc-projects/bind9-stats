package ISC::BIND::Stats::Parser;
use common::sense;
use base qw(XML::SAX::Base);

my $elements              = [];
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

sub start_element {
  my ( $self, $el ) = @_;

  # process element start event
  push @$elements, lc $el->{Name};

}

sub end_element {
  my ( $self, $el ) = @_;

  if ( $el->{Name} eq 'counters' ) {
    $valid_zone = 0;
  }

  pop @$elements;
}

sub characters {
  my ( $self, $data ) = @_;

  if ( $elements->[-1] eq 'name' && $elements->[-2] eq 'view' ) {
    $current_view = $data->{Data};
    return;
  }

  if ( $elements->[-1] eq 'name' && $elements->[-2] eq 'zone' ) {
    $current_zone = $data->{Data};
    $current_zone =~ s|/IN$||;
    return;
  }

  if (    $elements->[-1] eq 'serial'
       && $data->{Data} > 0 )
  {
    $valid_zone = 1;
    $zone->{$current_zone}->{serial} = $data->{Data};
    return;
  }
  if ( $elements->[-2] eq 'counters' ) {
    if ($valid_zone) {
      $zone->{$current_zone}->{counters}->{ $elements->[-1] } = $data->{Data};
      return;
    }
  }

  if ( $elements->[-2] eq 'server' ) {
    if ( $elements->[-1] eq 'boot-time' ) {
      $boot_time = $data->{Data};
      return;
    }
    if ( $elements->[-1] eq 'current-time' ) {
      $sample_time = $data->{Data};
      return;
    }
  }

  if (    $elements->[-4] eq 'server'
       && $elements->[-3] eq 'queries-in' )
  {
    if ( $elements->[-2] eq 'rdtype' ) {
      if ( $elements->[-1] eq 'name' ) {
        $current_query_counter = $data->{Data};
        return;
      }
      if ( $elements->[-1] eq 'counter' ) {
        $server->{requests}->{rdtype}->{$current_query_counter} = $data->{Data};
        return;
      }
    }
  }

  if ( $elements->[-3] eq 'requests' ) {
    if ( $elements->[-2] eq 'opcode' ) {
      if ( $elements->[-1] eq 'name' ) {
        $current_opcode = $data->{Data};
        return;
      }
      else {
        $server->{requests}->{opcode}->{$current_opcode} = $data->{Data};
        return;
      }
    }
  }

  if ( $elements->[-3] eq 'server' ) {
    if (    $elements->[-1] eq 'name'
         && $elements->[-2] eq 'nsstat' )
    {
      $current_nsstat = $data->{Data};
      return;
    }
    if (    $elements->[-1] eq 'counter'
         && $elements->[-2] eq 'nsstat' )
    {
      $server->{requests}->{nsstat}->{$current_nsstat} = $data->{Data};
      return;
    }

    if ( $elements->[-1] eq 'name' && $elements->[-2] eq 'zonestat' ) {
      $current_zonestat = $data->{Data};
      return;
    }
    if ( $elements->[-1] eq 'counter' && $elements->[-2] eq 'zonestat' ) {
      $server->{requests}->{zonestat}->{$current_zonestat} = $data->{Data};
      return;
    }
  }

}

sub end_document {
  return {
           zone            => $zone,
           sample_time     => $sample_time,
           boot_time       => $boot_time,
           server_counters => $server
  };

}

1;
