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

sub get_from_traffic : Private {
  my ( $self, $c, $args ) = @_;

  my $db = $c->model('BIND')->db;

  #find all unless provided
  $args->{find} ||= {};

  #fetch all unless specified
  $args->{wanted} ||= {};

  if ( ref $args->{key_sub} ne 'CODE' ) {
    $c->log->error(q{Must provide a code ref to extract the key: });
    return {};
  }

  $c->log->debug( q{Args: } . Dumper($args) );

  my $traffic_cursor = $db->traffic->find( $args->{find}, $args->{wanted} );

  my @series;

  my $set    = {};
  my $x_axis = {};

  while ( $traffic_cursor->has_next ) {
    my $data = $traffic_cursor->next;
    my $time =
      DateTime->from_epoch( epoch => $data->{_id}->{sample_time} / 1000 );
    my $jsTime = $time->epoch * 1000;

    my $key = $args->{key_sub}->($data);

    while ( my ( $k, $v ) = each %{ $data->{qps} } ) {
      $set->{$key}->{$jsTime} += $v if ( $k ne 'qryauthans' );
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

  return {
           categories    => \@x_axis,
           series        => \@series,
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
