package ISC::BIND::Stats::UI::Controller::Data;
use Moose;
use namespace::autoclean;

use DateTime;
use Number::Format;
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

ISC::BIND::Stats::UI::Controller::Data - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

my $nf = Number::Format->new;

sub index : Path : Args(0) {
  my ( $self, $c ) = @_;

  $c->response->redirect('/');
}

sub zone : Local {
  my ( $self, $c, $zone ) = @_;

  my $now = DateTime->now();

  my $params = {
    wanted => { qps => 1 },
    find =>
      { q{_id.sample_time} => { q{$gte} => ( $now->epoch - 86400 ) * 1000 } },
    key_sub => sub { return $_[0]->{_id}->{zone} }
  };

  if ($zone) {
    $c->log->debug( q{Setting zone to: } . $zone );
    $params->{find}->{q{_id.zone}} = $zone;
  }

  $c->stash->{data} = $c->forward( 'get_from_traffic', [$params] );

}

sub site : Local {
  my ( $self, $c, $server ) = @_;
  my $now = DateTime->now();

  my $params = {
    wanted => { qps => 1 },
    find =>
      { q{_id.sample_time} => { q{$gte} => ( $now->epoch - 86400 ) * 1000 } },
    key_sub => sub {
      $_[0]->{_id}->{pubservhost} =~ m{(\w{3}\d{1}).*?$};
      return $1;
      }
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

  my $params = {
      wanted => { nsstat_qps => 1 },
      find =>
        { q{_id.sample_time} => { q{$gte} => ( $now->epoch - 86400 ) * 1000 } },
      collection  => q{server_stats},
      dataset_sub => sub { return $_[0]->{nsstat_qps} },
      plot_wanted => [qw(Requestv4 Requestv6)],
      use_subkey  => 1
  };

  if ($server) {
    $c->log->debug( q{Setting server to: } . $server );
    $params->{find}->{q{_id.pubservhost}} = $server;
  }

  $c->stash->{data} = $c->forward( 'get_from_traffic', [$params] );
}

sub rdtype : Local {
  my ( $self, $c, $server ) = @_;
  my $now = DateTime->now();

  my $params = {
      wanted => { rdtype_qps => 1 },
      find =>
        { q{_id.sample_time} => { q{$gte} => ( $now->epoch - 86400 ) * 1000 } },
      collection  => q{server_stats},
      dataset_sub => sub { return $_[0]->{rdtype_qps} },
      use_subkey  => 1
  };

  if ($server) {
    $c->log->debug( q{Setting server to: } . $server );
    $params->{find}->{q{_id.pubservhost}} = $server;
  }

  $c->stash->{data} = $c->forward( 'get_from_traffic', [$params] );
}


sub opcode : Local {
  my ( $self, $c, $server ) = @_;
  my $now = DateTime->now();

  my $params = {
      wanted => { opcode_qps => 1 },
      find =>
        { q{_id.sample_time} => { q{$gte} => ( $now->epoch - 86400 ) * 1000 } },
      collection  => q{server_stats},
      dataset_sub => sub { return $_[0]->{opcode_qps} },
      use_subkey  => 1
  };

  if ($server) {
    $c->log->debug( q{Setting server to: } . $server );
    $params->{find}->{q{_id.pubservhost}} = $server;
  }

  $c->stash->{data} = $c->forward( 'get_from_traffic', [$params] );
}


sub tsig_sig0 : Local {
  my ( $self, $c, $server ) = @_;
  my $now = DateTime->now();

  my $params = {
      wanted => { nsstat_qps => 1 },
      find =>
        { q{_id.sample_time} => { q{$gte} => ( $now->epoch - 86400 ) * 1000 } },
      collection     => q{server_stats},
      dataset_sub    => sub { return $_[0]->{nsstat_qps} },
      plot_wanted    => [qw(ReqSIG0 ReqTSIG RespSIG0 RespTSIG)],
      plot_modifiers => [ 1, 1, -1, -1 ],
      use_subkey     => 1
  };

  if ($server) {
    $c->log->debug( q{Setting server to: } . $server );
    $params->{find}->{q{_id.pubservhost}} = $server;
  }

  $c->stash->{data} = $c->forward( 'get_from_traffic', [$params] );
}

sub edns0 : Local {
  my ( $self, $c, $server ) = @_;
  my $now = DateTime->now();

  my $params = {
      wanted => { nsstat_qps => 1 },
      find =>
        { q{_id.sample_time} => { q{$gte} => ( $now->epoch - 86400 ) * 1000 } },
      collection     => q{server_stats},
      dataset_sub    => sub { return $_[0]->{nsstat_qps} },
      plot_wanted    => [qw(ReqEdns0 RespEDNS0)],
      plot_modifiers => [ 1, -1 ],
      use_subkey     => 1
  };

  if ($server) {
    $c->log->debug( q{Setting server to: } . $server );
    $params->{find}->{q{_id.pubservhost}} = $server;
  }

  $c->stash->{data} = $c->forward( 'get_from_traffic', [$params] );
}

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

  if ( ref $args->{key_sub} ne 'CODE' && !$args->{use_subkey} ) {
    $c->log->error(q{Must provide a code ref to extract the key: });
    return {};
  }

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

  my @series;

  my $set    = {};
  my $x_axis = {};
  my $key;
  my $use_dataset_key = 0;
  while ( $traffic_cursor->has_next ) {
    my $data = $traffic_cursor->next;
    my $time =
      DateTime->from_epoch( epoch => $data->{_id}->{sample_time} / 1000 );
    my $jsTime = $time->epoch * 1000;

    if ( ref $args->{key_sub} ) {
      $key = $args->{key_sub}->($data);
    }
    else {
      $use_dataset_key = 1;
    }

    my $dataset = $dataset_sub->($data);

    while ( my ( $k, $v ) = each %{$dataset} ) {

      $key = $k if $use_dataset_key;

      if ( ref $args->{plot_wanted} ) {
        if ( $k ~~ $args->{plot_wanted} ) {
          if ( ref $plot_modifiers ) {
            $c->log->debug(qq{v: $v k: $k modifier: $plot_modifiers->{$k}});
            $v *= $plot_modifiers->{$k};
          }

          #$c->log->debug(qq{Pushing $k -> $jsTime += $v});
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

  foreach my $s ( keys %{$set} ) {
    my @d =
      map { [ $_ * 1, sprintf( q{%.2f}, $set->{$s}->{$_} ) * 1 ] } @x_axis;
    $total_traffic += $d[-1]->[1];
    push @series, { name => $s, data => \@d };
  }

  # $c->log->debug( Dumper( \@series ) );

  return {
           categories    => \@x_axis,
           series        => [ sort {$a->{name} cmp $b->{name} } @series ],
           traffic_count => $nf->format_number($total_traffic)
  };

}

sub end : Private {
  my ( $self, $c ) = @_;
  $c->forward('View::JSON');
}

=head1 AUTHOR

Francisco Obispo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
