package ISC::BIND::Stats::Parser;
use common::sense;
use base qw(XML::SAX::Base);


our $elements              = [];
our $current_view          = q{};
our $current_zone          = q{};
our $cluster_counters      = {};
our $current_query_counter = q{};
our $valid_zone            = 0;

our $boot_time;
our $sample_time;

our $zone = {};

sub start_document {
  my ( $self, $doc ) = @_;

  # process document start event
}

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
  }
  elsif ( $elements->[-1] eq 'name' && $elements->[-2] eq 'zone' ) {
    $current_zone = $data->{Data};
    $current_zone =~ s|/IN$||;
  }
  elsif (    $elements->[-1] eq 'serial'
          && $elements->[-2] eq 'zone'
          && $data->{Data} > 0 )
  {
    $valid_zone = 1;
    $zone->{$current_zone}->{serial} = $data->{Data};
  }
  elsif ( $elements->[-2] eq 'counters' ) {

    if ($valid_zone) {
      $zone->{$current_zone}->{counters}->{ $elements->[-1] } = $data->{Data};
    }
  }
  elsif ( $elements->[-1] eq 'boot-time' && $elements->[-2] eq 'server' ) {
    $boot_time = $data->{Data};
  }
  elsif ( $elements->[-1] eq 'current-time' && $elements->[-2] eq 'server' ) {
    $sample_time = $data->{Data};
  }
  elsif (    $elements->[-4] eq 'server'
          && $elements->[-3] eq 'queries-in'
          && $elements->[-2] eq 'rdtype' )
  {
    if ( $elements->[-1] eq 'name' ) {
      $current_query_counter =$data->{Data};
    }
    elsif ( $elements->[-1] eq 'counter' ) {
      $cluster_counters->{$current_query_counter} = $data->{Data};
    }
  }

}

sub end_document {
  return {
           zone             => $zone,
           sample_time      => $sample_time,
           boot_time        => $boot_time,
           cluster_counters => $cluster_counters
  };

}

1;
