# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ISC-BIND-Stats-Parser.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Data::Dumper;

# get reference results
use lib 't';
use sample;

BEGIN { plan tests => 11 }
BEGIN { use_ok('ISC::BIND::Stats') }
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $parser = ISC::BIND::Stats->new;

isa_ok( $parser, 'ISC::BIND::Stats' );

note('Parsing an XML file (v2)');

my $data = $parser->parse( { file => 't/XML/sample.xml' } );
ok(ref $data eq 'HASH','Data returned from parser (xml)');
cmp_deeply($data, $ISC::BIND::Stats::Sample::sample1, "v2 sample xml contents");

note('Parsing a bz2 file');

my $data_bz2 = $parser->parse( { file => 't/XML/sample.xml.bz2' } );
ok(ref $data_bz2 eq 'HASH','Data returned from parser (bz2)');

#diag(Dumper($data_bz2));


note(q{Trying to parse a emtpy file});

my $failed=$parser->parse({file=>undef});
ok(!$failed,q{Returned undef while parsing undef});

note(q{Creating one with arguments...});
my $with_args=ISC::BIND::Stats->new({test=>1});

isa_ok($with_args,'ISC::BIND::Stats');

ok($with_args->{test},'test arg was retained');

# this one will produce an error.
note(q{Trying to open an non-existant file});

my $nxfile=$parser->parse({file=>'/path/to/nowhere.xml'});
ok(!$nxfile,q{Non-existing file returned undef});

# this will also produce an error.
note(q{Trying to open a file that is not XML or BZ2});

my $invfile=$parser->parse({file=>'/etc/passwd'});
ok(!$invfile,q{Invalid file returned undef});

note('Parsing an XML file (v3)');

my $v3data = $parser->parse( { file => 't/XML/v3sample.xml.bz2' } );
ok(ref $v3data eq 'HASH','Data returned from parser (xml)');

done_testing();
