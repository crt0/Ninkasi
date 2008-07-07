#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 23;

use Apache::TestConfig;
use Ninkasi::Table;
use Smart::Comments;
use Test::WWW::Mechanize;

my $test_config = Apache::TestConfig->new();
my $url_base = join '', $test_config->{vars}{scheme}, '://',
                        $test_config->hostport();

my $dbh = Ninkasi::Table->new()->Database_Handle();
eval {
    $dbh->{PrintError} = 0;
    $dbh->do('DELETE FROM judge'       );
    $dbh->do("DELETE FROM 'constraint'");
    $dbh->{PrintError} = 1;
};

my $signup_url = "$url_base/cgi-bin/judge-signup";

my $mech = Test::WWW::Mechanize->new();

$mech->get_ok($signup_url);

$mech->submit_form_ok( {
    with_fields => {
        address             => '4996 Eighth',
        bjcp_id             => 'Z9990',
        category02          => 'prefer',
        category08          => 'entry',
        category10          => 'entry',
        category15          => 'entry',
        category20          => 'prefer not',
        category21          => 'entry',
        city                => 'Boise',
        competitions_judged => 10,
        email1              => 'ninkasi@ajk.name',
        email2              => 'ninkasi@ajk.name',
        first_name          => 'Leann',
        flight1             => 1,
        flight3             => 1,
        last_name           => 'Underhill',
        phone_day           => '628-268-5498',
        phone_evening       => '628-803-9648',
        rank                => 50,
        state               => 'ID',
        zip                 => '83730',
    }
} );

$mech->get_ok($signup_url);
$mech->submit_form_ok( {
    with_fields => {
        address             => '2239 Hale Cove',
        bjcp_id             => 'Z9991',
        city                => 'Ventura',
        competitions_judged => 2,
        email1              => 'ninkasi@ajk.name',
        email2              => 'ninkasi@ajk.name',
        first_name          => 'Liam',
        flight1             => 1,
        flight2             => 1,
        flight3             => 1,
        last_name           => 'Mayers',
        phone_day           => '964-722-0584',
        phone_evening       => '964-710-1677',
        pro_brewer          => 1,
        rank                => 10,
        state               => 'CA',
        zip                 => '93007',
    }
} );

$mech->get_ok($signup_url);
$mech->submit_form_ok( {
    with_fields => {
        address             => '7829 Drexel',
        bjcp_id             => 'Z9998',
        category02          => 'prefer',
        category08          => 'entry',
        category10          => 'entry',
        category15          => 'entry',
        category20          => 'prefer not',
        category21          => 'entry',
        city                => 'Laredo',
        competitions_judged => 10,
        email1              => 'ninkasi@ajk.name',
        email2              => 'ninkasi@ajk.name',
        first_name          => 'Greggory',
        flight1             => 1,
        flight3             => 1,
        last_name           => 'Reynoso',
        phone_day           => '512-700-9946',
        phone_evening       => '512-521-2449',
        rank                => 50,
        state               => 'TX',
        zip                 => '78043',
    }
} );


$mech->get_ok($signup_url);
$mech->submit_form_ok( {
    with_fields => {
        address             => '7046 Lahser',
        bjcp_id             => 'Z9998',
        category02          => 'prefer',
        category08          => 'entry',
        category10          => 'entry',
        category15          => 'entry',
        category20          => 'prefer not',
        category21          => 'entry',
        city                => 'Daytona Beach',
        competitions_judged => 10,
        email1              => 'ninkasi@ajk.name',
        email2              => 'ninkasi@ajk.name',
        first_name          => 'Angelina',
        flight1             => 1,
        flight3             => 1,
        last_name           => '|<iefer',
        phone_day           => '948-691-4519',
        phone_evening       => '948-643-3621',
        rank                => 50,
        state               => 'FL',
        zip                 => '32122',
    }
} );

$mech->get_ok($signup_url);
$mech->submit_form_ok( {
    with_fields => {
        address             => '5096 Kevin Lane',
        bjcp_id             => 'Z9998',
        category02          => 'prefer',
        category08          => 'entry',
        category10          => 'entry',
        category15          => 'entry',
        category20          => 'prefer not',
        category21          => 'entry',
        city                => 'Simms',
        competitions_judged => 10,
        email1              => 'ninkasi@ajk.name',
        email2              => 'ninkasi@ajk.name',
        first_name          => 'Lyndsey',
        flight1             => 1,
        flight3             => 1,
        last_name           => 'Carrera',
        phone_day           => '238-874-1701',
        phone_evening       => '238-293-9215',
        rank                => 50,
        state               => 'MT',
        zip                 => '59477',
    }
} );

# test view of all judges
my $lookup_url = "$url_base/cgi-bin/view/judge/";
$mech->get_ok($lookup_url);
$mech->content_like(qr{<a\ href="/cgi-bin/view/judge/[A-Za-z0-9=]{24}">\s+
                       |&lt;iefer,\ Angelina\s+
                       </a>\s+
                       </td>\s+
                       <td>Certified</td>\s+
                       <td>Y</td>\s+
                       <td>N</td>\s+
                       <td>Y</td>\s+
                       <td>10</td>\s+
                       <td>N</td>\s+
                       <td><a\ href="/cgi-bin/view/style/8">8</a>,\s+
                       <a\ href="/cgi-bin/view/style/10">10</a>,\s+
                       <a\ href="/cgi-bin/view/style/15">15</a>,\s+
                       <a\ href="/cgi-bin/view/style/21">21</a></td>\s+
                       <td><a\ href="/cgi-bin/view/style/20">20</a></td>\s+
                       <td><a\ href="/cgi-bin/view/style/1">1</a>,\s+
                       <a\ href="/cgi-bin/view/style/3">3</a>,\s+
                       <a\ href="/cgi-bin/view/style/4">4</a>,\s+
                       <a\ href="/cgi-bin/view/style/5">5</a>,\s+
                       <a\ href="/cgi-bin/view/style/6">6</a>,\s+
                       <a\ href="/cgi-bin/view/style/7">7</a>,\s+
                       <a\ href="/cgi-bin/view/style/9">9</a>,\s+
                       <a\ href="/cgi-bin/view/style/11">11</a>,\s+
                       <a\ href="/cgi-bin/view/style/12">12</a>,\s+
                       <a\ href="/cgi-bin/view/style/13">13</a>,\s+
                       <a\ href="/cgi-bin/view/style/14">14</a>,\s+
                       <a\ href="/cgi-bin/view/style/16">16</a>,\s+
                       <a\ href="/cgi-bin/view/style/17">17</a>,\s+
                       <a\ href="/cgi-bin/view/style/18">18</a>,\s+
                       <a\ href="/cgi-bin/view/style/19">19</a>,\s+
                       <a\ href="/cgi-bin/view/style/22">22</a>,\s+
                       <a\ href="/cgi-bin/view/style/23">23</a>,\s+
                       <a\ href="/cgi-bin/view/style/24">24</a></td>\s+
                       <td><a\ href="/cgi-bin/view/style/2">2</a></td>}msx);
$mech->content_like( qr{<title>Registered Judges</title>} );

# test view of individual judge information
$mech->follow_link_ok( { text_regex => qr/Mayers, Liam/ } );
$mech->content_like(qr{<h2>Liam\ Mayers</h2>\s+
                       <table\ class="view_judge">\s+
                       <tr>\s+
                       <th>Address:</th>\s+
                       <td>\s+
                       2239\ Hale\ Cove\s+
                       <br>\s+
                       Ventura,\ CA\ 93007\s+
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
                       </tr>\s+
                       <tr>\s+
                       <th>BJCP\ Rank:</th>\s+
                       <td>10</td>\s+
                       </tr>\s+
                       <tr>\s+
                       <th>BJCP\ ID:</th>\s+
                       <td>Z9991</td>\s+
                       </tr>\s+
                       <tr>\s+
                       <th>Competitions\ Judged:</th>\s+
                       <td>2</td>\s+
                       </tr>\s+
                       <tr>\s+
                       <th>Pro\ Brewer\?</th>\s+
                       <td>yes</td>\s+
                       </tr>}msx);
$mech->content_like( qr{<title>Liam Mayers</title>} );

# test category view
$lookup_url = "$url_base/cgi-bin/view/style/8";
$mech->get_ok($lookup_url);
$mech->content_like(qr{<a\ href="/cgi-bin/view/judge/[A-Za-z0-9=]{24}">\s+
                       Mayers,\ Liam\s+
                       </a>\s+
                       </td>\s+
                       <td>Novice</td>\s+
                       <td>Y</td>\s+
                       <td>Y</td>\s+
                       <td>Y</td>\s+
                       <td>2</td>\s+
                       <td>Y</td>\s+
                       <td>whatever</td>}msx);
$mech->content_like( qr{<title>Category 8. English Pale Ale</title>} );

# test CSV format for style with one judge
$mech->follow_link_ok( { text_regex => qr/CSV/ } );
$mech->content_is(<<EOF);
"Name","Rank","Fri. PM?","Sat. AM?","Sat. PM?","Comps Judged","Pro Brewer?","Preference"
"Mayers, Liam","Novice","Y","Y","Y","2","Y","whatever"
EOF

# test CSV format for style with multiple judges
$lookup_url = "$url_base/cgi-bin/view/style/1?format=csv";
$mech->get_ok($lookup_url);
$mech->content_is(<<EOF);
"Name","Rank","Fri. PM?","Sat. AM?","Sat. PM?","Comps Judged","Pro Brewer?","Preference"
"Underhill, Leann","Certified","Y","N","Y","10","N","whatever"
"Reynoso, Greggory","Certified","Y","N","Y","10","N","whatever"
"|&lt;iefer, Angelina","Certified","Y","N","Y","10","N","whatever"
"Carrera, Lyndsey","Certified","Y","N","Y","10","N","whatever"
"Mayers, Liam","Novice","Y","Y","Y","2","Y","whatever"
EOF
