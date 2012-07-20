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
  $c->stash->{page} = 'worldmap';
  $c->stash->{page_title}='World Wide Traffic Distribution';
  $c->stash->{page_subtitle}='from data collected during the last five (5) minutes';

}

=head2 site

Site report

=cut

sub site : Local {
  my ( $self, $c ) = @_;
  $c->stash->{page} = 'site';
  $c->stash->{page_title}='Site Traffic';
  $c->stash->{page_subtitle}='from data collected during the last five (5) minutes';
  $c->stash->{info_message}=q{This graph has 'zoom-in' features, please select a region and the graph
  will be zoomed in.. If the range is within a week, it will trigger an 'hourly' resolution. If the
  range is within a day, it will show a 5 minute intervals.
  };
}



=head2 zone 

Provides a page to see the data on a per-zone basis 

=cut

sub zone : Local {
  my ( $self, $c ) = @_;
  $c->stash->{page} = 'zone';
  $c->stash->{page_title}='Zone Traffic';
  $c->stash->{page_subtitle}='from data collected during the last five (5) minutes';
}


=head2 zone_detail

Provides zone detailed information

=cut

sub zone_detail : Local {
  my ( $self, $c, $zone) = @_;
  
  $c->stash->{page} = 'zone_detail';
  $c->stash->{page_title}='Zone Detail';
  $c->stash->{page_subtitle}='from data collected during the last five (5) minutes';
  

  
 
  $c->stash->{zone_name}=$zone;
}


=head2 v6v4

Provides a page to analyze network traffic.

=cut

sub v6v4 : Local {
  my ( $self, $c ) = @_;

  $c->stash->{page} = 'v6v4';
  $c->stash->{page_title}='IPv6 and IPv4 Traffic';
  $c->stash->{page_subtitle}='from data collected during the last five (5) minutes';
}



=head2 tsigsig0

Provides a page to analyze network traffic.

=cut

sub tsig_sig0 : Local {
  my ( $self, $c ) = @_;
  $c->stash->{page} = 'tsig_sig0';
  $c->stash->{page_title}='TSIG and SIG0 Traffic';
  $c->stash->{page_subtitle}='from data collected during the last five (5) minutes';

}


=head2 rtdtype

Provides a page to analyze network traffic.

=cut

sub rdtype : Local {
  my ( $self, $c ) = @_;
  $c->stash->{page} = 'rdtype';
  $c->stash->{page_title}='Query Types Received';
  $c->stash->{page_subtitle}='from data collected during the last five (5) minutes';
}

=head2 edns0

Provides a page to analyze network traffic.

=cut

sub edns0 : Local {
  my ( $self, $c ) = @_;
  $c->stash->{page} = 'edns0';
  $c->stash->{page_title}='DNS Extensions';
  $c->stash->{page_subtitle}='from data collected during the last five (5) minutes';

}

=head2 opcode

Provides a page to analyze network traffic.

=cut

sub opcode : Local {
  my ( $self, $c ) = @_;
  $c->stash->{page} = 'opcode';
  $c->stash->{page_title}='Operational Codes';
  $c->stash->{page_subtitle}='from data collected during the last five (5) minutes';
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
