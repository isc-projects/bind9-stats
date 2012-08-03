package ISC::BIND::Stats::UI::Controller::Data;
use Moose;
use namespace::autoclean;

use DateTime;
use Number::Format;
use Data::Dumper;

use Geo::IATA;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

ISC::BIND::Stats::UI::Controller::Data - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

my $nf = Number::Format->new;
my $g;
my $config;

sub begin : Private {
  my ( $self, $c ) = @_;
  $config = $c->config;
  return 1;
}

=head2 index
  This method is only there to prevent any errors when calling the /data/
  path. 
  
  It should just return an empty hash.

=cut

sub index : Path : Args(0) {
  my ( $self, $c ) = @_;
  $c->stash->{data} = {};

}

=head2 zone
  returns a the data using the zone name as the key.
  
=cut

sub zone : Local {
  my ( $self, $c, @zones ) = @_;

  my $now = DateTime->now();

  $c->log->info( Dumper(@zones) );

  if ( q{root} ~~ \@zones ) {

    foreach my $z (@zones) {
      $z =~ s{^root$}{\.};
    }

  }

  my $params = {
    collection  => q{global_traffic_daily},
    wanted      => { q{value.qps} => 1 },
    dataset_sub=> sub {return $_[0]->{value}->{qps}},
    plot_wanted => [
        qw(qryformerr qryreferral qrynxdomain qryservfail qrysuccess qrynxrrset)
    ],
    #find => {
    #   q{_id.sample_time} =>
    #     { q{$gte} => DateTime->from_epoch( epoch => ( $now->epoch - 86400 ) ) }
    #},
    key_sub => sub {
      my $z = $_[0]->{_id}->{zone};    # extract the zone name from the doc
      $z =~ s{^\.$}{root};             # replace the '.' with 'root'
      return $z;                       # return the resulting name
      }
  };

  my $zones_find = [];

  foreach my $zone (@zones) {
    push @{$zones_find}, { q{_id.zone} => $zone };
  }

  if ( scalar @{$zones_find} ) {
    $params->{find}->{q{$or}} = $zones_find;
  }

  $c->stash->{data} = $c->forward( 'get_from_traffic', [$params] );

}

sub zone_detail : Local {
  my ( $self, $c, $zone ) = @_;

  my $now = DateTime->now();

  $zone //= q{};
  $zone =~ s{^root$}{\.};

  my $params = {
    wanted => { qps => 1 },
    find   => {
            q{_id.sample_time} => { q{$gte} => ( $now->epoch - 86400 ) * 1000 },
            q{_id.zone}        => $zone
    },
    plot_wanted => [
        qw(qryformerr qryreferral qrynxdomain qryservfail qrysuccess qrynxrrset)
    ],

  };

  if ($zone) {
    $c->stash->{data} = $c->forward( 'get_from_traffic', [$params] );
  }
  else {
    $c->stash->{data} = {};
  }
}

sub site : Local {
  my ( $self, $c, $server ) = @_;
  my $now = DateTime->now();

  my $from = $c->request->param(q{from}) || 0;
  my $to   = $c->request->param(q{to})   || 0;

  if ( $from && $to ) {
    ( $from, $to ) = map { sprintf( q{%d}, $_ ) * 1 } $from, $to;
  }
  my $params = {
    wanted  => { qps => 1 },
    key_sub => sub {
      $_[0]->{_id}->{pubservhost} =~
        m{(\w{3}\d{1}).*?$};    # use the pubservhost name but
                                # use only the first three leters
                                # that identify the site name
      return $1;
      }
  };

  if ( $from && $to ) {
    $params->{find} = {
                        q{_id.sample_time} => {
                                                q{$gte} => $from,
                                                q{$lte} => $to
                        }
    };
  }
  else {
    $params->{find} =
      { q{_id.sample_time} => { q{$gte} => ( $now->epoch - 86400 ) * 1000 } };
  }

  if ($server) {
    $c->log->debug( q{Setting server to: } . $server );
    $params->{find}->{q{_id.pubservhost}} = $server;
  }

  $c->stash->{data} = $c->forward( 'get_from_traffic', [$params] );
}

sub site_hourly : Local {
  my ( $self, $c, $server ) = @_;

  my $now = DateTime->now;

  my $from = $c->request->param(q{from}) || 0;
  my $to   = $c->request->param(q{to})   || 0;

  if ( $from && $to ) {
    ( $from, $to ) =
      map { DateTime->from_epoch( epoch => sprintf( q{%d}, $_ / 1000 ) * 1 ) }
      $from, $to;
  }

  my $params = {
    wanted  => { q{value.qps} => 1 },
    key_sub => sub {
      $_[0]->{_id}->{pubservhost} =~ m{(\w{3}\d{1}).*?$};
      return $1;
    },
    dataset_sub => sub { return $_[0]->{value}->{qps} },
    collection  => q{rescode_traffic_hourly}
  };

  if ( $from && $to ) {
    $params->{find} = {
                        q{_id.sample_time} => {
                                                q{$gte} => $from,
                                                q{$lte} => $to
                        }
    };
  }
  else {
    $params->{find} =
      { q{_id.sample_time} =>
        { q{$gte} => DateTime->from_epoch( epoch => $now->epoch - 604800 ) } };
  }

  if ($server) {
    $c->log->debug( q{Setting server to: } . $server );
    $params->{find}->{q{_id.pubservhost}} = $server;
  }

  $c->stash->{data} = $c->forward( 'get_from_traffic', [$params] );

}

sub site_daily : Local {
  my ( $self, $c, $server ) = @_;

  my $params = {
    wanted  => { q{value.qps} => 1 },
    find    => {},
    key_sub => sub {
      $_[0]->{_id}->{pubservhost} =~ m{(\w{3}\d{1}).*?$};
      return $1;
    },
    dataset_sub => sub { return $_[0]->{value}->{qps} },
    collection  => q{rescode_traffic_daily}
  };

  if ($server) {
    $c->log->debug( q{Setting server to: } . $server );
    $params->{find}->{q{_id.pubservhost}} = $server;
  }

  $c->stash->{data} = $c->forward( 'get_from_traffic', [$params] );

}

sub server : Local {
  my ( $self, $c, $server ) = @_;
  my $now = DateTime->now();

  my $params = {
    wanted => { qps => 1 },
    find =>
      { q{_id.sample_time} => { q{$gte} => ( $now->epoch - 86400 ) * 1000 } },
    key_sub => sub {
      $_[0]->{_id}->{pubservhost} =~ m{(\w{3}\d{1}\w{1}).*?$};
      return $1;
      }
  };

  if ($server) {
    $c->log->debug( q{Setting server to: } . $server );
    $params->{find}->{q{_id.pubservhost}} = $server;
  }

  $c->stash->{data} = $c->forward( 'get_from_traffic', [$params] );

}

sub v6v4 : Local {
  my ( $self, $c, $server ) = @_;
  my $now = DateTime->now();

  my $from = $c->request->param(q{from}) || 0;
  my $to   = $c->request->param(q{to})   || 0;

  if ( $from && $to ) {
    ( $from, $to ) =
      map { DateTime->from_epoch( epoch => sprintf( q{%d}, $_ / 1000 ) * 1 ) }
      $from, $to;
  }
  my $params = {
                 wanted     => { q{value.nsstat_qps} => 1 },
                 collection => q{global_server_stats_5min},
                 dataset_sub => sub { return $_[0]->{value}->{nsstat_qps} },
                 plot_wanted => [qw(Requestv4 Requestv6)],
  };

  if ( $from && $to ) {
    $params->{find} = {
                        q{_id.sample_time} => {
                                                q{$gte} => $from,
                                                q{$lte} => $to
                        }
    };
  }
  else {
    $params->{find} =
      { q{_id.sample_time} =>
        { q{$gte} => DateTime->from_epoch( epoch => $now->epoch - 86400 ) } };
  }

  $c->stash->{data} = $c->forward( 'get_from_traffic', [$params] );
}

sub v6v4_daily : Local {
  my ( $self, $c, $server ) = @_;

  my $params = {
                 wanted     => { q{value.nsstat_qps} => 1 },
                 collection => q{global_server_stats_daily},
                 dataset_sub => sub { return $_[0]->{value}->{nsstat_qps} },
                 plot_wanted => [qw(Requestv4 Requestv6)],
  };

  $c->stash->{data} = $c->forward( 'get_from_traffic', [$params] );
}

sub v6v4_hourly : Local {
  my ( $self, $c, $server ) = @_;
  my $now = DateTime->now();

  my $from = $c->request->param(q{from}) || 0;
  my $to   = $c->request->param(q{to})   || 0;

  if ( $from && $to ) {
    ( $from, $to ) =
      map { DateTime->from_epoch( epoch => sprintf( q{%d}, $_ / 1000 ) * 1 ) }
      $from, $to;
  }

  my $params = {
                 wanted     => { q{value.nsstat_qps} => 1 },
                 collection => q{global_server_stats_hourly},
                 dataset_sub => sub { return $_[0]->{value}->{nsstat_qps} },
                 plot_wanted => [qw(Requestv4 Requestv6)],
  };

  if ( $from && $to ) {
    $params->{find} = {
                        q{_id.sample_time} => {
                                                q{$gte} => $from,
                                                q{$lte} => $to
                        }
    };
  }
  else {
    $params->{find} =
      { q{_id.sample_time} =>
        { q{$gte} => DateTime->from_epoch( epoch => $now->epoch - 604800 ) } };
  }

  $c->stash->{data} = $c->forward( 'get_from_traffic', [$params] );
}

sub rdtype : Local {
  my ( $self, $c, $server ) = @_;
  my $now = DateTime->now();

  my $from = $c->request->param(q{from}) || 0;
  my $to   = $c->request->param(q{to})   || 0;

  if ( $from && $to ) {
    ( $from, $to ) =
      map { DateTime->from_epoch( epoch => sprintf( q{%d}, $_ / 1000 ) * 1 ) }
      $from, $to;
  }
  my $params = {
                 wanted     => { q{value.rdtype_qps} => 1 },
                 collection => q{global_server_stats_5min},
                 dataset_sub => sub { return $_[0]->{value}->{rdtype_qps} },
  };

  if ( $from && $to ) {
    $params->{find} = {
                        q{_id.sample_time} => {
                                                q{$gte} => $from,
                                                q{$lte} => $to
                        }
    };
  }
  else {
    $params->{find} =
      { q{_id.sample_time} =>
        { q{$gte} => DateTime->from_epoch( epoch => $now->epoch - 86400 ) } };
  }

  $c->stash->{data} = $c->forward( 'get_from_traffic', [$params] );
}

sub rdtype_hourly : Local {
  my ( $self, $c, $server ) = @_;
  my $now = DateTime->now();

  my $from = $c->request->param(q{from}) || 0;
  my $to   = $c->request->param(q{to})   || 0;

  if ( $from && $to ) {
    ( $from, $to ) =
      map { DateTime->from_epoch( epoch => sprintf( q{%d}, $_ / 1000 ) * 1 ) }
      $from, $to;
  }

  my $params = {
                 wanted     => { q{value.rdtype_qps} => 1 },
                 collection => q{global_server_stats_hourly},
                 dataset_sub => sub { return $_[0]->{value}->{rdtype_qps} },
  };

  if ( $from && $to ) {
    $params->{find} = {
                        q{_id.sample_time} => {
                                                q{$gte} => $from,
                                                q{$lte} => $to
                        }
    };
  }
  else {
    $params->{find} =
      { q{_id.sample_time} =>
        { q{$gte} => DateTime->from_epoch( epoch => $now->epoch - 604800 ) } };
  }

  $c->stash->{data} = $c->forward( 'get_from_traffic', [$params] );
}

sub rdtype_daily : Local {
  my ( $self, $c, $server ) = @_;
  my $now = DateTime->now();

  my $params = {
                 wanted     => { q{value.rdtype_qps} => 1 },
                 collection => q{global_server_stats_daily},
                 dataset_sub => sub { return $_[0]->{value}->{rdtype_qps} },
  };

  $params->{find} =
    { q{_id.sample_time} =>
      { q{$gte} => DateTime->from_epoch( epoch => $now->epoch - 604800 ) } };

  $c->stash->{data} = $c->forward( 'get_from_traffic', [$params] );
}

sub opcode : Local {
  my ( $self, $c, $server ) = @_;
  my $now = DateTime->now();

  my $from = $c->request->param(q{from}) || 0;
  my $to   = $c->request->param(q{to})   || 0;

  if ( $from && $to ) {
    ( $from, $to ) =
      map { DateTime->from_epoch( epoch => sprintf( q{%d}, $_ / 1000 ) * 1 ) }
      $from, $to;
  }

  my $params = {
                 wanted     => { q{value.opcode_qps} => 1 },
                 collection => q{global_server_stats_5min},
                 dataset_sub => sub { return $_[0]->{value}->{opcode_qps} },
  };

  if ( $from && $to ) {
    $params->{find} = {
                        q{_id.sample_time} => {
                                                q{$gte} => $from,
                                                q{$lte} => $to
                        }
    };
  }
  else {
    $params->{find} =
      { q{_id.sample_time} =>
        { q{$gte} => DateTime->from_epoch( epoch => $now->epoch - 86400 ) } };
  }

  $c->stash->{data} = $c->forward( 'get_from_traffic', [$params] );
}

sub opcode_hourly : Local {
  my ( $self, $c, $server ) = @_;
  my $now = DateTime->now();

  my $from = $c->request->param(q{from}) || 0;
  my $to   = $c->request->param(q{to})   || 0;

  if ( $from && $to ) {
    ( $from, $to ) =
      map { DateTime->from_epoch( epoch => sprintf( q{%d}, $_ / 1000 ) * 1 ) }
      $from, $to;
  }

  my $params = {
                 wanted     => { q{value.opcode_qps} => 1 },
                 collection => q{global_server_stats_hourly},
                 dataset_sub => sub { return $_[0]->{value}->{opcode_qps} },
  };

  if ( $from && $to ) {
    $params->{find} = {
                        q{_id.sample_time} => {
                                                q{$gte} => $from,
                                                q{$lte} => $to
                        }
    };
  }
  else {
    $params->{find} =
      { q{_id.sample_time} =>
        { q{$gte} => DateTime->from_epoch( epoch => $now->epoch - 604800 ) } };
  }

  $c->stash->{data} = $c->forward( 'get_from_traffic', [$params] );
}

sub opcode_daily : Local {
  my ( $self, $c, $server ) = @_;
  my $now = DateTime->now();

  my $params = {
                 wanted     => { q{value.opcode_qps} => 1 },
                 collection => q{global_server_stats_daily},
                 dataset_sub => sub { return $_[0]->{value}->{opcode_qps} },
  };

  $params->{find} =
    { q{_id.sample_time} =>
      { q{$gte} => DateTime->from_epoch( epoch => $now->epoch - 604800 ) } };

  $c->stash->{data} = $c->forward( 'get_from_traffic', [$params] );
}

sub tsig_sig0 : Local {
  my ( $self, $c, $server ) = @_;
  my $now = DateTime->now();

  my $from = $c->request->param(q{from}) || 0;
  my $to   = $c->request->param(q{to})   || 0;

  if ( $from && $to ) {
    ( $from, $to ) =
      map { DateTime->from_epoch( epoch => sprintf( q{%d}, $_ / 1000 ) * 1 ) }
      $from, $to;
  }

  my $params = {
    wanted => { q{value.nsstat_qps} => 1 },

    collection     => q{global_server_stats_5min},
    dataset_sub    => sub { return $_[0]->{value}->{nsstat_qps} },
    plot_wanted    => [qw(ReqSIG0 ReqTSIG RespSIG0 RespTSIG)],
    plot_modifiers => [ 1, 1, -1, -1 ],
  };

  if ( $from && $to ) {
    $params->{find} = {
                        q{_id.sample_time} => {
                                                q{$gte} => $from,
                                                q{$lte} => $to
                        }
    };
  }
  else {
    $params->{find} =
      { q{_id.sample_time} =>
        { q{$gte} => DateTime->from_epoch( epoch => $now->epoch - 86400 ) } };
  }

  $c->stash->{data} = $c->forward( 'get_from_traffic', [$params] );
}

sub tsig_sig0_hourly : Local {
  my ( $self, $c, $server ) = @_;
  my $now = DateTime->now();

  my $from = $c->request->param(q{from}) || 0;
  my $to   = $c->request->param(q{to})   || 0;

  if ( $from && $to ) {
    ( $from, $to ) =
      map { DateTime->from_epoch( epoch => sprintf( q{%d}, $_ / 1000 ) * 1 ) }
      $from, $to;
  }

  my $params = {
                 wanted     => { q{value.nsstat_qps} => 1 },
                 collection => q{global_server_stats_hourly},
                 dataset_sub => sub { return $_[0]->{value}->{nsstat_qps} },
                 plot_wanted    => [qw(ReqSIG0 ReqTSIG RespSIG0 RespTSIG)],
                 plot_modifiers => [ 1, 1, -1, -1 ],
  };

  if ( $from && $to ) {
    $params->{find} = {
                        q{_id.sample_time} => {
                                                q{$gte} => $from,
                                                q{$lte} => $to
                        }
    };
  }
  else {
    $params->{find} =
      { q{_id.sample_time} =>
        { q{$gte} => DateTime->from_epoch( epoch => $now->epoch - 604800 ) } };
  }

  $c->stash->{data} = $c->forward( 'get_from_traffic', [$params] );
}

sub tsig_sig0_daily : Local {
  my ( $self, $c, $server ) = @_;
  my $now = DateTime->now();

  my $params = {
                 wanted     => { q{value.nsstat_qps} => 1 },
                 collection => q{global_server_stats_daily},
                 dataset_sub => sub { return $_[0]->{value}->{nsstat_qps} },
                 plot_wanted    => [qw(ReqSIG0 ReqTSIG RespSIG0 RespTSIG)],
                 plot_modifiers => [ 1, 1, -1, -1 ],
  };

  $params->{find} =
    { q{_id.sample_time} =>
      { q{$gte} => DateTime->from_epoch( epoch => $now->epoch - 604800 ) } };

  $c->stash->{data} = $c->forward( 'get_from_traffic', [$params] );
}

sub edns0 : Local {
  my ( $self, $c, $server ) = @_;
  my $now = DateTime->now();

  my $from = $c->request->param(q{from}) || 0;
  my $to   = $c->request->param(q{to})   || 0;

  if ( $from && $to ) {
    ( $from, $to ) =
      map { DateTime->from_epoch( epoch => sprintf( q{%d}, $_ / 1000 ) * 1 ) }
      $from, $to;
  }

  my $params = {
                 wanted     => { q{value.nsstat_qps} => 1 },
                 collection => q{global_server_stats_5min},
                 dataset_sub => sub { return $_[0]->{value}->{nsstat_qps} },
                 plot_wanted    => [qw(ReqEdns0 RespEDNS0)],
                 plot_modifiers => [ 1, -1 ],
  };

  if ( $from && $to ) {
    $params->{find} = {
                        q{_id.sample_time} => {
                                                q{$gte} => $from,
                                                q{$lte} => $to
                        }
    };
  }
  else {
    $params->{find} =
      { q{_id.sample_time} =>
        { q{$gte} => DateTime->from_epoch( epoch => $now->epoch - 86400 ) } };
  }

  $c->stash->{data} = $c->forward( 'get_from_traffic', [$params] );
}

sub edns0_hourly : Local {
  my ( $self, $c, $server ) = @_;
  my $now = DateTime->now();

  my $from = $c->request->param(q{from}) || 0;
  my $to   = $c->request->param(q{to})   || 0;

  if ( $from && $to ) {
    ( $from, $to ) =
      map { DateTime->from_epoch( epoch => sprintf( q{%d}, $_ / 1000 ) * 1 ) }
      $from, $to;
  }

  my $params = {
                 wanted     => { q{value.nsstat_qps} => 1 },
                 collection => q{global_server_stats_hourly},
                 dataset_sub => sub { return $_[0]->{value}->{nsstat_qps} },
                 plot_wanted    => [qw(ReqEdns0 RespEDNS0)],
                 plot_modifiers => [ 1, -1 ],
  };

  if ( $from && $to ) {
    $params->{find} = {
                        q{_id.sample_time} => {
                                                q{$gte} => $from,
                                                q{$lte} => $to
                        }
    };
  }
  else {
    $params->{find} =
      { q{_id.sample_time} =>
        { q{$gte} => DateTime->from_epoch( epoch => $now->epoch - 604800 ) } };
  }

  $c->stash->{data} = $c->forward( 'get_from_traffic', [$params] );
}

sub edns0_daily : Local {
  my ( $self, $c, $server ) = @_;
  my $now = DateTime->now();

  my $params = {
                 wanted     => { q{value.nsstat_qps} => 1 },
                 collection => q{global_server_stats_daily},
                 dataset_sub => sub { return $_[0]->{value}->{nsstat_qps} },
                 plot_wanted    => [qw(ReqEdns0 RespEDNS0)],
                 plot_modifiers => [ 1, -1 ],
  };

  $params->{find} =
    { q{_id.sample_time} =>
      { q{$gte} => DateTime->from_epoch( epoch => $now->epoch - 604800 ) } };

  $c->stash->{data} = $c->forward( 'get_from_traffic', [$params] );
}

sub location_table : Local {
  my ( $self, $c, ) = @_;
  my $now = DateTime->now();

  $g = Geo::IATA->new( $config->{geo_iata_db} );

  my $params = {
    wanted => { qps => 1 },
    find =>
      { q{_id.sample_time} => { q{$gte} => ( $now->epoch - 600 ) * 1000 } },
    key_sub => sub {
      $_[0]->{_id}->{pubservhost} =~ m{^(\w{3}).*?$};
      return $g->iata2location($1);
    },
    order => { q{_id.sample_time} => -1 }
  };

  my $data = $c->forward( 'get_from_traffic', [$params] );
  my $series = [ [ 'Location', 'Percent (%)', 'Traffic (qps)' ] ];

  #$c->log->debug( Dumper($data) );

  # Pull the max value from the series that we want:

  my $max   = 0;
  my $total = 0;
  foreach my $s ( @{ $data->{series} } ) {
    $max = $s->{data}->[-1]->[-1] > $max ? $s->{data}->[-1]->[-1] : $max;
    $total += $s->{data}->[-1]->[-1];
  }

  map {
    push @{$series},
      [
        $_->{name},
        sprintf( '%d', ( ( $_->{data}->[-1]->[-1] ) / $total ) * 100 ) * 1,
        $_->{data}->[-1]->[-1] * 1
      ]
  } @{ $data->{series} };

  $c->stash->{data} = { table => $series };

}

=item get_from_traffic

This subroutine was design to centralize all the data fetches from
mongo. The main reason for this, is because all the queries are very
similar, and the data processing needed to perform such operations
is already too cumbersome to have several copies around.

The sub has been implemented in such a way that its behavior can
be heavily modified via arguments.

The sub receives a single hash reference with the following
options:

{
  wanted      => { field=> 1 },        # same as MongoDB wanted feature
  find        => { field=> "value" },  # same as MongoDB find argument
  order       => { field=> -1 },       # same as MongoDB cursor sort
  key_sub     => sub { my $data=shift; # filter to set/transform the key
                    return $data->{_id}->{pubservhost};
                  },
  dataset_sub    => sub { return $_[0]->{nsstat_qps} }, # sub to select the dataset
  plot_wanted    => [qw(ReqEdns0 RespEDNS0)],     # fields to select from the dataset
  plot_modifiers => [ 1, -1 ],                    # multipliers for the data (i.e.: if you want the first
                                                  # ReqEdns0 positive but RespEDNS0 negative)
}

=cut

sub get_from_traffic : Private {
  my ( $self, $c, $args ) = @_;

  my $db = $c->model('BIND')->db;

  #find all unless provided
  $args->{find} ||= {};

  #fetch all unless specified
  $args->{wanted} ||= {};

  # defaults to 'traffic' collection
  my $collection = $args->{collection} || q{traffic};

  my $dataset_sub = $args->{dataset_sub} || sub { return $_[0]->{qps} };

  # plot modifiers
  my $plot_modifiers;

  if ( ref $args->{plot_modifiers} && $args->{plot_wanted} ) {
    $plot_modifiers = {};
    for ( my $w = 0 ; $w < scalar @{ $args->{plot_wanted} } ; $w++ ) {
      $plot_modifiers->{ $args->{plot_wanted}->[$w] } =
        $args->{plot_modifiers}->[$w];
    }
  }

  $c->log->debug( q{Args: } . Dumper($args) );

  my $traffic_cursor = $db->$collection->find( $args->{find}, $args->{wanted} );

  if ( $args->{order} ) {
    $traffic_cursor->sort( $args->{order} );
  }

  my @series;

  my $set    = {};
  my $x_axis = {};
  my $key;
  my $use_dataset_key = 0;

  $c->log->debug( q{Records to be retrieved: } . $traffic_cursor->count );

  while ( $traffic_cursor->has_next ) {
    my $data        = $traffic_cursor->next;
    my $sample_time = $data->{_id}->{sample_time};
    my $time =
      ref $sample_time
      ? $sample_time
      : DateTime->from_epoch( epoch => $data->{_id}->{sample_time} / 1000 );
    my $jsTime = $time->epoch * 1000;

    if ( ref $args->{key_sub} ) {
      $key = $args->{key_sub}->($data);
    }
    else {
      $use_dataset_key = 1;
    }

    my $dataset = $dataset_sub->($data);

    while ( my ( $k, $v ) = each %{$dataset} ) {
  #    $c->log->debug('k: ' . $k . ' v: ' . $v);
      $key = $k if $use_dataset_key;

      if ( ref $args->{plot_wanted} ) {
        if ( $k ~~ $args->{plot_wanted} ) {
          if ( ref $plot_modifiers ) {
            $v *= $plot_modifiers->{$k};
          }
          $set->{$key}->{$jsTime} += $v;
        }
      }
      else {
        $set->{$key}->{$jsTime} += $v if ( $k ne 'qryauthans' );
      }
    }

    $x_axis->{$jsTime}++;
  }

  my @x_axis          = sort { $a <=> $b } keys %{$x_axis};
  my $total_traffic   = 0;
  my $node_query_load = [];
  my $min             = 0;
  my $max             = 0;

   #$c->log->debug('Set: ' . Dumper($set));

  foreach my $s ( keys %{$set} ) {
    my @d =
      map { [ $_ * 1, sprintf( q{%.2f}, $set->{$s}->{$_} // 0 ) * 1 ] } @x_axis;
    $total_traffic += $d[-1]->[1];
    $min = $min > $d[-1]->[1] || !$min ? $d[-1]->[1] : $min;
    $max = $max < $d[-1]->[1] ? $d[-1]->[1] : $max;
    push @series, { name => $s, data => \@d };
  }

  # $c->log->debug( Dumper( \@series ) );

  return {
           categories    => \@x_axis,
           series        => [ sort { $a->{name} cmp $b->{name} } @series ],
           traffic_count => $nf->format_number($total_traffic),
           min           => $min,
           max           => $max
  };

}

sub end : Private {
  my ( $self, $c ) = @_;
  $c->forward('View::JSON');
}

=head1 LICENSE

BSD

=head1 COPYRIGHT

Copyright (C) 2004-2012  Internet Systems Consortium, Inc. ("ISC")

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND ISC DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS.  IN NO EVENT SHALL ISC BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS SOFTWARE.

=cut

__PACKAGE__->meta->make_immutable;

1;
