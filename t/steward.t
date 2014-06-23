#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 41;

use File::LibMagic qw/:easy/;
use Ninkasi::Test;

our $test_object = Ninkasi::Test->new();
our $mech = $test_object->mech();
our $url_base = $test_object->url_base();

our $judge_signup_url  = "$url_base/register";
our $steward_signup_url = "$judge_signup_url?role=steward";
$mech->get_ok($steward_signup_url);
$mech->content_lacks('Register to Judge');

sub register_steward {
    my ($fields) = @_;

    $mech->get_ok($steward_signup_url);
    $mech->form_number(2);
    $mech->set_fields(@$fields);
    $mech->click_button( value => 'Register to Steward' );
    ok $mech->success();

    return;
}

register_steward [
    address1            => '2239 Hale Cove',
    city                => 'Millarville',
    country             => 'Canada',
    email1              => 'ninkasi@ajk.name',
    email2              => 'ninkasi@ajk.name',
    first_name          => 'Liam',
    session1            => 1,
    session2            => 1,
    session3            => 1,
    last_name           => 'Mayers',
    phone_day           => '964-722-0584',
    phone_evening       => '964-710-1677',
    state               => 'AB',
    zip                 => 'T0L 1K0',
];

register_steward [
    address1            => '7829 Drexel',
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

register_steward [
    address1            => '7046 Lahser',
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

register_steward [
    address1            => '5096 Kevin Lane',
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

# test view of all stewards
my $lookup_url = "$url_base/manage/steward/";
$mech->get_ok($lookup_url);
$mech->content_like(
    qr{<td><a\ href="/manage/steward/\d+">\|&lt;iefer,\ Angelina</a></td>\s+
       <td></td>\s+
       <td>N/A</td>\s+
       <td></td>}msx,
    'steward view',
);
$mech->content_like( qr{<title>Registered Stewards</title>},
                     'steward view title' );
$mech->html_lint_ok('HTML validation');

# test CSV format for view of all stewards
$mech->follow_link_ok( { text_regex => qr/csv/ } );
is $mech->ct(), 'text/plain';
$mech->content_is( <<EOF, 'CSV steward view' );
"Name","Fri. PM","Sat. AM","Sat. PM"
"Carrera, Lyndsey","","N/A",""
"Mayers, Liam","","",""
"Reynoso, Greggory","","N/A",""
"|<iefer, Angelina","","N/A",""
EOF

# test roster
$mech->back();
$mech->follow_link_ok( { text_regex => qr/print/ } );
is $mech->ct(), 'application/pdf';
like MagicBuffer( $mech->content() ), qr/PDF/;

# test view of individual steward information
$mech->back();
$mech->follow_link_ok( { text_regex => qr/Mayers, Liam/ } );
$mech->content_like(qr{<h2>Liam\ Mayers</h2>\s+
                       <table\ class="view_judge">\s+
                       <tr>\s+
                       <th>Address:</th>\s+
                       <td>\s+
                       2239\ Hale\ Cove\s+
                       <br>\s+
                       Millarville,\s+
                       AB\s+
                       Canada\s+
                       T0L\ 1K0\s+
                       </td>\s+
                       </tr>\s+
                       <tr>\s+
                       <th>Phone\ \(day\):</th>\s+
                       <td>964-722-0584</td>\s+
                       </tr>\s+
                       <tr>\s+
                       <th>Phone\ \(eve\):</th>\s+
                       <td>964-710-1677</td>\s+
                       </tr>\s+
                       <tr>\s+
                       <th>E-mail:</th>\s+
                       <td>ninkasi\@ajk\.name</td>\s+
                       </tr>}msx,
                'individual steward view');
$mech->content_like( qr{<title>Liam Mayers</title>},
                     'individual steward view title' );

# test view of individual steward information with html encoding
$mech->back();
$mech->follow_link_ok( { text_regex => qr/iefer, Angelina/ } );
$mech->content_like( qr{<h2>Angelina |&lt;iefer</h2>},
                     'HTML-encoded steward view' );
$mech->content_like( qr{<title>Angelina \|&lt;iefer</title>},
                     'HTML-encoded steward view title' );

# test table card (just make sure it's a PDF)
$mech->back();
$mech->follow_link_ok( { text_regex => qr/print/ } );
is $mech->ct(), 'application/pdf';
like MagicBuffer( $mech->content() ), qr/PDF/;

# add a judge to make sure she doesn't show up as a steward
$mech->get_ok($judge_signup_url);
$mech->submit_form_ok( {
    with_fields => {
        address1            => '4996 Eighth',
        bjcp_id             => 'Z9990',
        category02          => 'prefer',
        category08          => 'entry',
        category10          => 'entry',
        category14          => 'prefer',
        category15          => 'entry',
        category20          => 'prefer not',
        category21          => 'prefer',
        city                => 'Boise',
        competitions_judged => 10,
        email1              => 'ninkasi@ajk.name',
        email2              => 'ninkasi@ajk.name',
        first_name          => 'Leann',
        session1            => 1,
        session2            => 1,
        last_name           => 'Underhill',
        phone_day           => '628-268-5498',
        phone_evening       => '628-803-9648',
        rank                => 50,
        state               => 'ID',
        zip                 => '83730',
    }
} );
$lookup_url = "$url_base/manage/steward/";
$mech->get_ok($lookup_url);
$mech->content_lacks( 'Underhill', 'steward view does not contain judges' );

# make sure stewards don't show up as judges
$lookup_url = "$url_base/manage/judge/";
$mech->get_ok($lookup_url);
$mech->content_contains( 'Underhill', 'judge view contains judge' );
$mech->content_lacks( 'Mayers', 'judge view does not contain steward' );

# add flights
$lookup_url = "$url_base/manage/flight/";
$mech->get_ok($lookup_url);
my %data = (
    category    => [ 2, 8, 10, 14, 14 ],
    name        => [ qw/02 08 10 14b 14a/ ],
    pro         => [ undef, 1, (undef) x 3 ],
    description => [
        'Pilsner',
        'English Pale Ale',
        'American Ale',
        'India Pale Ale, Table B',
        'India Pale Ale, Table A',
    ],
);
my %input = ();
foreach my $row ( 1 .. 5 ) {
    while ( my ( $name, $value ) = each %data ) {
        $input{ "${name}_$row" } = $value->[ $row - 1 ];
    }
}
$mech->submit_form_ok( { button => 'save', with_fields => \%input } );

# make sure stewards don't show up as judges on assignment pages
$lookup_url = "$url_base/manage/assignment/08";
$mech->get_ok($lookup_url);
$mech->content_contains( 'Underhill', 'assignment view contains judge' );
$mech->content_lacks( 'Mayers', 'assignment view does not contain judge' );
