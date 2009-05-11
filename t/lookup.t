#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 24;

use Apache::TestConfig;
use Ninkasi::Table;
use Test::WWW::Mechanize;

my $test_config = Apache::TestConfig->new();
my $url_base = join '', $test_config->{vars}{scheme}, '://',
                        $test_config->hostport();

my $dbh = Ninkasi::Table->new()->Database_Handle();
eval {
    $dbh->{PrintError} = 0;
    $dbh->do('DELETE FROM judge'       );
    $dbh->do('DELETE FROM category'    );
    $dbh->do("DELETE FROM 'constraint'");
    $dbh->{PrintError} = 1;
};

my $signup_url = "$url_base/register-to-judge";

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
my $lookup_url = "$url_base/manage/judge/";
$mech->get_ok($lookup_url);
$mech->content_like(
    qr{<a\ href="judge/[1-9][0-9]*">\s+
       |&lt;iefer,\ Angelina\s+
       </a>\s+
       </td>\s+
       <td>Certified</td>\s+
       <td></td>\s+
       <td>N/A</td>\s+
       <td></td>\s+
       <td>10</td>\s+
       <td>N</td>\s+
       <td><a\ href="../assignment/8">8</a>,\s+
       <a\ href="../assignment/10">10</a>,\s+
       <a\ href="../assignment/15">15</a>,\s+
       <a\ href="../assignment/21">21</a></td>\s+
       <td><a\ href="../assignment/20">20</a></td>\s+
       <td><a\ href="../assignment/1">1</a>,\s+
       <a\ href="../assignment/3">3</a>,\s+
       <a\ href="../assignment/4">4</a>,\s+
       <a\ href="../assignment/5">5</a>,\s+
       <a\ href="../assignment/6">6</a>,\s+
       <a\ href="../assignment/7">7</a>,\s+
       <a\ href="../assignment/9">9</a>,\s+
       <a\ href="../assignment/11">11</a>,\s+
       <a\ href="../assignment/12">12</a>,\s+
       <a\ href="../assignment/13">13</a>,\s+
       <a\ href="../assignment/14">14</a>,\s+
       <a\ href="../assignment/16">16</a>,\s+
       <a\ href="../assignment/17">17</a>,\s+
       <a\ href="../assignment/18">18</a>,\s+
       <a\ href="../assignment/19">19</a>,\s+
       <a\ href="../assignment/22">22</a>,\s+
       <a\ href="../assignment/23">23</a>,\s+
       <a\ href="../assignment/24">24</a></td>\s+
       <td><a\ href="../assignment/2">2</a></td>}msx
);
$mech->content_like( qr{<title>Registered Judges</title>} );

# test CSV format for view of all judges
$mech->follow_link_ok( { text_regex => qr/csv/ } );
$mech->content_is(<<EOF);
"Name","Rank","Fri. PM","Sat. AM","Sat. PM","Comps Judged","Pro Brewer?","Entries","Prefers Not","Whatever","Prefers"
"Carrera, Lyndsey","Certified","","N/A","","10","N","8, 10, 15, 21","20","1, 3, 4, 5, 6, 7, 9, 11, 12, 13, 14, 16, 17, 18, 19, 22, 23, 24","2"
"Mayers, Liam","Novice","","","","2","Y","","","1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24",""
"Reynoso, Greggory","Certified","","N/A","","10","N","8, 10, 15, 21","20","1, 3, 4, 5, 6, 7, 9, 11, 12, 13, 14, 16, 17, 18, 19, 22, 23, 24","2"
"Underhill, Leann","Certified","","N/A","","10","N","8, 10, 15, 21","20","1, 3, 4, 5, 6, 7, 9, 11, 12, 13, 14, 16, 17, 18, 19, 22, 23, 24","2"
"|&lt;iefer, Angelina","Certified","","N/A","","10","N","8, 10, 15, 21","20","1, 3, 4, 5, 6, 7, 9, 11, 12, 13, 14, 16, 17, 18, 19, 22, 23, 24","2"
EOF

# test view of individual judge information
$mech->back();
$mech->follow_link_ok( { text_regex => qr/Mayers, Liam/ } );
$mech->content_like(qr{<h2>Liam\ Mayers</h2>\s+
                       <table\ class="view_judge">\s+
                       <tr>\s+
                       <th>Address:</th>\s+
                       <td>\s+
                       2239\ Hale\ Cove\s+
                       <br>\s+
                       Ventura,\s+
                       CA\s+
                       93007\s+
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
                       <td>Novice</td>\s+
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

# test view of individual judge information with html encoding
$mech->back();
$mech->follow_link_ok( { text_regex => qr/iefer, Angelina/ } );
$mech->content_like( qr{<h2>Angelina |&lt;iefer</h2>} );
$mech->content_like( qr{<title>Angelina |&lt;iefer</title>} );

# test category view
$lookup_url = "$url_base/manage/assignment/8";
$mech->get_ok($lookup_url);
$mech->content_like(
    qr{<a\ href="\d+">\s+
       Mayers,\ Liam\s+
       </a>\s+
       </td>\s+
       <td>Novice</td>\s+
       <td>\s+
       <input\ name="assign"\ type="checkbox"\ value="judge2,flight1"\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="assign"\ type="checkbox"\ value="judge2,flight2"\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="assign"\ type="checkbox"\ value="judge2,flight3"\ />\s+
       </td>\s+
       <td>2</td>\s+
       <td>Y</td>\s+
       <td>whatever</td>}msx
);
$mech->content_like( qr{<title>Category 8. English Pale Ale</title>} );
