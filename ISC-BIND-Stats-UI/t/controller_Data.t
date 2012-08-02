use strict;
use warnings;
use Test::More;

use Try::Tiny;
use JSON;
use Data::Dumper;

use warnings FATAL => qw( all );

use Catalyst::Test 'ISC::BIND::Stats::UI';
use ISC::BIND::Stats::UI::Controller::Data;

my $json = JSON->new->allow_nonref;

my $req_zone=request(q{/data/zone});
ok( $req_zone->is_success, q{Zone Request to /data/zone should succeed});
ok(&check_content($req_zone),q{Content for zone was verified});

my $req_zone_detail=request(q{/data/zone_detail/root});
ok( $req_zone_detail->is_success, q{Zone Request to /data/zone_detail should succeed});
ok(&check_content($req_zone_detail),q{Content for zone_detail was verified});

my $req_site=request(q{/data/site});
ok( $req_site->is_success, q{Zone Request to /data/site should succeed});
ok(&check_content($req_site),q{Content for site was verified});

my $req_site_hourly=request(q{/data/site_hourly});
ok( $req_site_hourly->is_success, q{Zone Request to /data/site_hourly should succeed});
ok(&check_content($req_site_hourly),q{Content for site_hourly was verified});

my $req_site_daily=request(q{/data/site_daily});
ok( $req_site_daily->is_success, q{Zone Request to /data/site_daily should succeed});
ok(&check_content($req_site_daily),q{Content for site_daily was verified});

my $req_server=request(q{/data/server});
ok( $req_server->is_success, q{Zone Request to /data/server should succeed});
ok(&check_content($req_server),q{Content for server was verified});

my $req_v6v4=request(q{/data/v6v4});
ok( $req_v6v4->is_success, q{Zone Request to /data/v6v4 should succeed});
ok(&check_content($req_v6v4),q{Content for v6v4 was verified});

my $req_rdtype=request(q{/data/rdtype});
ok( $req_rdtype->is_success, q{Zone Request to /data/rdtype should succeed});
ok(&check_content($req_rdtype),q{Content for rdtype was verified});

my $req_opcode=request(q{/data/opcode});
ok( $req_opcode->is_success, q{Zone Request to /data/opcode should succeed});
ok(&check_content($req_opcode),q{Content for opcode was verified});

my $req_tsig_sig0=request(q{/data/tsig_sig0});
ok( $req_tsig_sig0->is_success, q{Zone Request to /data/tsig_sig0 should succeed});
ok(&check_content($req_tsig_sig0),q{Content for tsig_sig0 was verified});

my $req_edns0=request(q{/data/edns0});
ok( $req_edns0->is_success, q{Zone Request to /data/edns0 should succeed});
ok(&check_content($req_edns0),q{Content for edns0 was verified});

my $req_location_table=request(q{/data/location_table});
ok( $req_location_table->is_success, q{Zone Request to /data/location_table should succeed});


done_testing();

sub check_content {
  my ($response) = @_;

  my $data;

  my $raw=$response->content;
  
  
  note('request was made to: ' . $response->request->uri);
  
  ok($raw,"response has data");
  
  $data = $json->decode( $raw );

  ok(ref $data eq 'HASH','Data was in JSON format');

  ok(defined $data->{min},'data has minimum');
  note(Dumper($data->{min}));


  ok(defined $data->{max},'data mas maximum');
  note(Dumper($data->{max}));
  
  ok(ref $data->{series} eq 'ARRAY','has an array reference with values' );
  note(Dumper($data->{series}));
  
  ok(defined $data->{traffic_count},' has the last traffic count');
  note(Dumper($data->{traffic_count}));
  
  ok(ref $data->{categories} eq 'ARRAY','has an array reference with cateogries');
  note(Dumper($data->{categories}));


  return ref $data eq 'HASH' ? 1 : 0;

}
