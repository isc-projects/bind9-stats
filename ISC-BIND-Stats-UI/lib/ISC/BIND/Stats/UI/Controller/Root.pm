package ISC::BIND::Stats::UI::Controller::Root;
use Moose;
use namespace::autoclean;
use Data::Dumper;
use Encode;

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
  $c->stash->{page}          = 'worldmap';
  $c->stash->{page_title}    = 'World Wide Traffic Distribution';
  $c->stash->{page_subtitle} = q{<div id='subtitle'></div>};

}

=head2 site

Site report

=cut

sub site : Local {
  my ( $self, $c ) = @_;
  $c->stash->{page}          = 'site';
  $c->stash->{page_title}    = 'Site Traffic';
  $c->stash->{page_subtitle} = 'from averages collected every five minutes';
  $c->stash->{info_message} =
    q{This graph has 'zoom-in' features, please select a region and the graph
  will be zoomed in.. If the range is within a week, it will trigger an 'hourly' resolution. If the
  range is within a day, it will show a 5 minute intervals.
  };
}

=head2 site_detail

Detail on a site

=cut

sub site_detail : Local {
  my ( $self, $c, $site ) = @_;

  if ( !$site || !( $site =~ m/^\w{3}\d{1}/ ) ) {
    $c->stash->{error_message} = 'Unknown site';
    $c->detach('site');
  }

  $c->stash->{page} = 'site_detail';

  $site =~ m/^(\w{3})/;
  my $iata = uc $1;
  my $site_data =
    $c->model('BIND')->db->locations->find( { _id => $iata } )->next;

  $c->log->debug( 'Data about site: ' . Dumper($site_data) );

  $c->stash->{site_name} = $site;
  $c->stash->{site_info} = $site_data;

  my $addr_components = $site_data->{value}->{address_components};

  my $country;

  foreach my $addr ( @{$addr_components} ) {
    if ( 'country' ~~ $addr->{types} ) {
      $country = $addr;
      last;
    }
  }

  $c->log->debug( "Country: " . Dumper($country) );

  $c->stash->{wanted_region} = $country->{short_name};
  $c->stash->{page_title} = sprintf(
                                     'Site Detail for %s',
                                     #encode_utf8(
                                        $site_data->{value}->{formatted_address}
                                     #)
  );
  $c->stash->{page_subtitle} = sprintf( 'code name %s', uc $site );

}

=head2 zone 

Provides a page to see the data on a per-zone basis 

=cut

sub zone : Local {
  my ( $self, $c, @args ) = @_;
  $c->stash->{page}          = 'zone';
  $c->stash->{page_title}    = 'Zone Traffic';
  $c->stash->{page_subtitle} = 'from averages collected every five minutes';

  if ( scalar @args ) {
    $c->stash->{zones} = \@args;
  }

}

=head2 zone_detail

Provides zone detailed information

=cut

sub zone_detail : Local {
  my ( $self, $c, $zone ) = @_;

  $c->stash->{page}          = 'zone_detail';
  $c->stash->{page_title}    = 'Zone Detail';
  $c->stash->{page_subtitle} = 'from averages collected every five minutes';

  $c->stash->{zone_name} = $zone;
}

=head2 v6v4

Provides a page to analyze network traffic.

=cut

sub v6v4 : Local {
  my ( $self, $c ) = @_;

  $c->stash->{page}          = 'v6v4';
  $c->stash->{page_title}    = 'IPv6 and IPv4 Traffic';
  $c->stash->{page_subtitle} = 'from averages collected every five minutes';
}

=head2 tsigsig0

Provides a page to analyze network traffic.

=cut

sub tsig_sig0 : Local {
  my ( $self, $c ) = @_;
  $c->stash->{page}          = 'tsig_sig0';
  $c->stash->{page_title}    = 'TSIG and SIG0 Traffic';
  $c->stash->{page_subtitle} = 'from averages collected every five minutes';

}

=head2 rtdtype

Provides a page to analyze network traffic.

=cut

sub rdtype : Local {
  my ( $self, $c ) = @_;
  $c->stash->{page}          = 'rdtype';
  $c->stash->{page_title}    = 'Query Types Received';
  $c->stash->{page_subtitle} = 'from averages collected every five minutes';
}

=head2 edns0

Provides a page to analyze network traffic.

=cut

sub edns0 : Local {
  my ( $self, $c ) = @_;
  $c->stash->{page}          = 'edns0';
  $c->stash->{page_title}    = 'DNS Extensions';
  $c->stash->{page_subtitle} = 'from averages collected every five minutes';

}

=head2 opcode

Provides a page to analyze network traffic.

=cut

sub opcode : Local {
  my ( $self, $c ) = @_;
  $c->stash->{page}          = 'opcode';
  $c->stash->{page_title}    = 'Operational Codes';
  $c->stash->{page_subtitle} = 'from averages collected every five minutes';
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
