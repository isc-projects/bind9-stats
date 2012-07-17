package ISC::BIND::Stats::UI::Controller::Root;
use Moose;
use namespace::autoclean;
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config( namespace => '' );

=head1 NAME

ISC::BIND::Stats::UI::Controller::Root - Root Controller for ISC::BIND::Stats::UI

=head1 DESCRIPTION

Provides an interface to the statistics collected from IO::BIND::Stats, which are
stored in MongoDB

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index : Path : Args(0) {
  my ( $self, $c ) = @_;
  $c->stash->{page} = 'main';

}

=head2 zone 

Provides a page to see the data on a per-zone basis 

=cut

sub zone : Local {
  my ( $self, $c, $zone ) = @_;
  $c->stash->{page} = 'zone';

 

}

=head2 default

Standard 404 error page

=cut

sub default : Path {
  my ( $self, $c ) = @_;
  $c->response->body('Page not found');
  $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {
  my ( $self, $c ) = @_;

  if ( !$c->stash->{template} || $c->response->body ) {
    my $config = $c->config;

    $c->stash->{site_title}     = $config->{site_title};
    $c->stash->{site_copyright} = $config->{site_copyright};

    $c->stash->{template} = sprintf( '%s.tt', $c->stash->{page} );
  }
}

=head1 AUTHOR

Francisco Obispo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
