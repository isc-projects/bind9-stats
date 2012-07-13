package ISC::BIND::Stats;
use common::sense;

use feature ':5.10';

use version;
our $VERSION = qv('1.1');

use IO::Uncompress::Bunzip2;
use IO::File;

use XML::SAX::ParserFactory;
use ISC::BIND::Stats::Parser;

sub new {
  my ( $class, $args ) = @_;

  my $self = $args || {};
  bless $self, $class;

  $self->{parser} =
    XML::SAX::ParserFactory->parser(
                                   Handler => ISC::BIND::Stats::Parser->new() );

  return $self;
}

sub parse {
  my ( $self, $args ) = @_;
  if ( $args->{file} ) {
    my $file = $self->_open_file( $args->{file} );
    if($file){
      return $self->{parser}->parse_file($file);
    }
    else{
      warn('Error opening file');
      return;
    }
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
      die(q{File must be .xml or .bz2});
    }
  }

}

1;
