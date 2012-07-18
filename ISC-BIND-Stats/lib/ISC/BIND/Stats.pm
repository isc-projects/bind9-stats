
=head1 NAME

ISC::Stats::Parser - Parses the XML from BIND9 statistics channel

=head1 SYNOPSIS

  my $parser=ISC::BIND::Parser->new;
  my $hashref_result=$parser->parse({file=>'/path/to/file.xml'});


=head1 DESCRIPTION

This module parses the XML produced from BIND9 stats channel. It is meant for high speed parsing,
with the purpose of statistical aggregation.

=head1 EXPORT

None by default.

=cut

package ISC::BIND::Stats;
use common::sense;

use feature ':5.10';

use version;
our $VERSION = qv('1.42');

use IO::Uncompress::Bunzip2;
use IO::File;

use XML::SAX::ParserFactory;
use ISC::BIND::Stats::Parser;

=item new

Create a new instance of ISC::BIND::Stats

=cut

sub new {
  my ( $class, $args ) = @_;

  my $self = $args || {};
  bless $self, $class;

  $self->{parser} =
    XML::SAX::ParserFactory->parser(
                                   Handler => ISC::BIND::Stats::Parser->new() );

  return $self;
}

=item parse

Receives a .xml file (plain or compressed with bzip2), parses it using
L<ISC::BIND::Stats::Parser> and returns a reference to a HASH with 
the resulting values.


arguments: 

for file: { file => '/path/to/file.xml'}

=cut

sub parse {
  my ( $self, $args ) = @_;
  if ( $args->{file} ) {
    my $file = $self->_open_file( $args->{file} );
    if ($file) {
      return $self->{parser}->parse_file($file);
    }
    else {
      warn('Error opening file');
      return;
    }
  }
 
  else {
    warn(q{Must pass either the file or url argument});
    return;
  }

}

=item _open_file

Receives a scalar with the file that needs to opened and returns
a IO::Handle compatible object (IO::File or IO::Uncompress:Bunzip2)
depending whether the file is compressed or not.

=cut

sub _open_file {
  my ( $self, $file ) = @_;

  given ($file) {
    when ( $_ =~ m/\.bz2$/ ) {
      return IO::Uncompress::Bunzip2->new( $file, BlockSize => 16384 );
    }
    when ( $_ =~ m/\.xml$/ ) {
      return IO::File->new($file);
    }
    default {
      warn(q{File must be .xml or .bz2});
      return;
    }
  }

}

1;

__END__

=back

=head1 SEE ALSO

  http://www.isc.org

=head1 AUTHOR

Internet Systems Consortium Inc.

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



