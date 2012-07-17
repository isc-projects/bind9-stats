use strict;
use warnings;
use Test::More;


use Catalyst::Test 'ISC::BIND::Stats::UI';
use ISC::BIND::Stats::UI::Controller::Data;

ok( request('/data')->is_success, 'Request should succeed' );
done_testing();
