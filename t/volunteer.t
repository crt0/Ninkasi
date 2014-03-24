#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 18;

use File::LibMagic qw/:easy/;
use Ninkasi::Test;

our $test_object = Ninkasi::Test->new();
our $mech = $test_object->mech();
our $url_base = $test_object->url_base();

my $signup_url = "$url_base/register";
sub register {
    my ( $role, $fields ) = @_;

    $mech->get_ok("$signup_url?role=$role");
    $mech->form_number(2);
    $mech->set_fields(@$fields);
    $mech->click_button( value => 'Register to ' . ucfirst $role );
    ok $mech->success();

    return;
}

register judge => [
        address             => '2239 Hale Cove',
        bjcp_id             => 'Z9991',
        city                => 'Ventura',
        competitions_judged => 2,
        email1              => 'ninkasi@ajk.name',
        email2              => 'ninkasi@ajk.name',
        first_name          => 'Liam',
        session1            => 1,
        session2            => 1,
        session3            => 1,
        last_name           => 'Mayers',
        phone_day           => '964-722-0584',
        phone_evening       => '964-710-1677',
        pro_brewer          => 1,
        rank                => 10,
        state               => 'CA',
        zip                 => '93007',
];

register steward => [
    address             => '7829 Drexel',
    city                => 'Laredo',
    email1              => 'ninkasi@ajk.name',
    email2              => 'ninkasi@ajk.name',
    first_name          => 'Greggory',
    session1            => 1,
    session3            => 1,
    last_name           => 'Reynoso',
    phone_day           => '512-700-9946',
    phone_evening       => '512-521-2449',
    state               => 'TX',
    zip                 => '78043',
];

register steward => [
    address             => '7046 Lahser',
    city                => 'Daytona Beach',
    email1              => 'ninkasi@ajk.name',
    email2              => 'ninkasi@ajk.name',
    first_name          => 'Angelina',
    session1            => 1,
    session3            => 1,
    last_name           => '|<iefer',
    phone_day           => '948-691-4519',
    phone_evening       => '948-643-3621',
    state               => 'FL',
    zip                 => '32122',
];

register steward => [
    address             => '5096 Kevin Lane',
    city                => 'Simms',
    email1              => 'ninkasi@ajk.name',
    email2              => 'ninkasi@ajk.name',
    first_name          => 'Lyndsey',
    session1            => 1,
    session3            => 1,
    last_name           => 'Carrera',
    phone_day           => '238-874-1701',
    phone_evening       => '238-293-9215',
    state               => 'MT',
    zip                 => '59477',
];

# test view of all volunteers
my $lookup_url = "$url_base/manage/volunteer/";
$mech->get_ok($lookup_url);
$mech->content_like(
    qr{<td><a\ href="/manage/steward/\d+">\|&lt;iefer,\ Angelina</a></td>\s+
       <td></td>\s+
       <td>7046\ Lahser,\ Daytona\ Beach,\ FL\ 32122</td>\s+
       <td>948-691-4519</td>\s+
       <td>948-643-3621</td>\s+
       <td>ninkasi\@ajk\.name</td>\s+
       <td></td>}msx,
    'volunteer view',
);
$mech->content_like( qr{<title>Registered Volunteers</title>},
                     'volunteer view title' );
$mech->html_lint_ok('HTML validation');

# test CSV format for view of all stewards
$mech->follow_link_ok( { text_regex => qr/csv/ } );
is $mech->ct(), 'text/plain';
$mech->content_is( <<'EOF', 'CSV steward view' );
"Name","Rank","Address","Phone (day)","Phone (eve)","E-mail","BJCP id"
"Carrera, Lyndsey","","5096 Kevin Lane, Simms, MT 59477","238-874-1701","238-293-9215","ninkasi@ajk.name",""
"Mayers, Liam","Novice","2239 Hale Cove, Ventura, CA 93007","964-722-0584","964-710-1677","ninkasi@ajk.name","Z9991"
"Reynoso, Greggory","","7829 Drexel, Laredo, TX 78043","512-700-9946","512-521-2449","ninkasi@ajk.name",""
"|<iefer, Angelina","","7046 Lahser, Daytona Beach, FL 32122","948-691-4519","948-643-3621","ninkasi@ajk.name",""
EOF

# test roster
$mech->back();
$mech->follow_link_ok( { text_regex => qr/print/ } );
is $mech->ct(), 'application/pdf';
like MagicBuffer( $mech->content() ), qr/PDF/;
