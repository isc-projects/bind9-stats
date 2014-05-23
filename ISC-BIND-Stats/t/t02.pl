#!/usr/bin/perl

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use lib '../lib';

use Test::More;
use Data::Dumper;

use ISC::BIND::Stats;

my $parser = ISC::BIND::Stats->new;

# turn on detailed debugging
$parser->{parser}->{Handler}->{bind9statsdebug} = 1;
print "Parser: ",Dumper($parser->{parser}->{Handler});
#my $data = $parser->parse( { file => 't/XML/v3sample.xml' } );
my $data = $parser->parse( { file => 't/XML/sample.xml' } );
print Dumper($data);

