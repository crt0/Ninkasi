#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 40;

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
    $dbh->do("DELETE FROM assignment");
    $dbh->do("DELETE FROM flight");
    $dbh->{PrintError} = 1;
};

my $mech = Test::WWW::Mechanize->new();

# with no flights configured yet, looking for one should cause a 404
my $lookup_url = "$url_base/manage/assignment/8";
$mech->get($lookup_url);
is $mech->status(), 404;
$mech->content_like(qr/Flight 8 not found\./);

# test empty flight table
$lookup_url = "$url_base/manage/flight/";
$mech->get_ok($lookup_url);
$mech->content_like(
    qr{<tr\ class="odd">\s+
       <td>\s+
       <input\ name="number_1"\s+
               size="3"\s+
               value=""\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="category_1"\s+
               size="3"\s+
               value=""\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="pro_1"\s+
               type="checkbox"\s+
               value="1"\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="description_1"\s+
               size="40"\s+
               value=""\ />\s+
       </td>\s+
       </tr>}msx
);

# add flights
my %data = (
    category    => [ 2, 8, 10, 15, 20 ],
    pro         => [ undef, 1, (undef) x 3 ],
    description => [
        'Pilsner',
        'English Pale Ale',
        'American Ale',
        'German Wheat and Rye Beer',
        'Fruit Beer',
    ],
);
my %input = ();
foreach my $row ( 1 .. 5 ) {
    while ( my ( $name, $value ) = each %data ) {
        $input{ "${name}_$row" } = $value->[ $row - 1 ];
    }
    $input{"number_$row"} = $input{"category_$row"};
}
$mech->submit_form_ok( { button => 'save', with_fields => \%input } );
$mech->content_like(
    qr{<tr\ class="even">\s+
       <td>\s+
       <input\ name="number_2"\s+
               size="3"\s+
               value="8"\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="category_2"\s+
               size="3"\s+
               value="8"\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="pro_2"\s+
               checked="checked"\s+
               type="checkbox"\s+
               value="1"\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="description_2"\s+
               size="40"\s+
               value="English\ Pale\ Ale"\ />\s+
       </td>\s+
       </tr>}msx
);

# add another row
$mech->submit_form_ok( {
    button      => 'save',
    with_fields => {
        number_6      => 21,
        category_6    => 21,
        description_6 => 'Spice/Herb/Vegetable Beer',
    }
} );
$mech->content_like(
    qr{<tr\ class="even">\s+
       <td>\s+
       <input\ name="number_6"\s+
               size="3"\s+
               value="21"\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="category_6"\s+
               size="3"\s+
               value="21"\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="pro_6"\s+
               type="checkbox"\s+
               value="1"\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="description_6"\s+
               size="40"\s+
               value="Spice/Herb/Vegetable\ Beer"\ />\s+
       </td>\s+
       </tr>}msx
);

my $signup_url = "$url_base/register-to-judge";
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
        session1            => 1,
        session3            => 1,
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
        session1            => 1,
        session3            => 1,
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
        session1            => 1,
        session3            => 1,
        last_name           => 'Carrera',
        phone_day           => '238-874-1701',
        phone_evening       => '238-293-9215',
        rank                => 50,
        state               => 'MT',
        zip                 => '59477',
    }
} );

# test view of all judges
$lookup_url = "$url_base/manage/judge/";
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
       <td><a\ href="/manage/assignment/8">8</a>,\s+
       <a\ href="/manage/assignment/10">10</a>,\s+
       <a\ href="/manage/assignment/15">15</a>,\s+
       <a\ href="/manage/assignment/21">21</a></td>\s+
       <td><a\ href="/manage/assignment/20">20</a></td>\s+
       <td><a\ href="/manage/assignment/1">1</a>,\s+
       <a\ href="/manage/assignment/3">3</a>,\s+
       <a\ href="/manage/assignment/4">4</a>,\s+
       <a\ href="/manage/assignment/5">5</a>,\s+
       <a\ href="/manage/assignment/6">6</a>,\s+
       <a\ href="/manage/assignment/7">7</a>,\s+
       <a\ href="/manage/assignment/9">9</a>,\s+
       <a\ href="/manage/assignment/11">11</a>,\s+
       <a\ href="/manage/assignment/12">12</a>,\s+
       <a\ href="/manage/assignment/13">13</a>,\s+
       <a\ href="/manage/assignment/14">14</a>,\s+
       <a\ href="/manage/assignment/16">16</a>,\s+
       <a\ href="/manage/assignment/17">17</a>,\s+
       <a\ href="/manage/assignment/18">18</a>,\s+
       <a\ href="/manage/assignment/19">19</a>,\s+
       <a\ href="/manage/assignment/22">22</a>,\s+
       <a\ href="/manage/assignment/23">23</a>,\s+
       <a\ href="/manage/assignment/24">24</a></td>\s+
       <td><a\ href="/manage/assignment/2">2</a></td>}msx
);
$mech->content_like( qr{<title>Registered Judges</title>} );
$mech->html_lint_ok('HTML validation');

# test CSV format for view of all judges
$mech->follow_link_ok( { text_regex => qr/csv/ } );
$mech->content_is(<<EOF);
"Name","Rank","Fri. PM","Sat. AM","Sat. PM","Comps Judged","Pro Brewer?","Entries","Prefers Not","Whatever","Prefers"
"Carrera, Lyndsey","Certified","","N/A","","10","N","8, 10, 15, 21","20","1, 3, 4, 5, 6, 7, 9, 11, 12, 13, 14, 16, 17, 18, 19, 22, 23, 24","2"
"Mayers, Liam","Novice","","","","2","Y","","","1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24",""
"Reynoso, Greggory","Certified","","N/A","","10","N","8, 10, 15, 21","20","1, 3, 4, 5, 6, 7, 9, 11, 12, 13, 14, 16, 17, 18, 19, 22, 23, 24","2"
"Underhill, Leann","Certified","","","N/A","10","N","8, 10, 15, 21","20","1, 3, 4, 5, 6, 7, 9, 11, 12, 13, 14, 16, 17, 18, 19, 22, 23, 24","2"
"|<iefer, Angelina","Certified","","N/A","","10","N","8, 10, 15, 21","20","1, 3, 4, 5, 6, 7, 9, 11, 12, 13, 14, 16, 17, 18, 19, 22, 23, 24","2"
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
       <input\ name="assign"\s+
               type="checkbox"\s+
               value="judge-2_session-1"\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="assign"\s+
               type="checkbox"\s+
               value="judge-2_session-2"\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="assign"\s+
               type="checkbox"\s+
               value="judge-2_session-3"\ />\s+
       </td>\s+
       <td>2</td>\s+
       <td>Y</td>\s+
       <td>whatever</td>}msx
);
$mech->content_unlike(
    qr{<a\ href="\d+">\s+
       Mayers,\ Liam\s+
       </a>\s+
       </td>\s+
       <td>Novice</td>\s+
       <td>\s+
       </td>\s+
       <td>\s+
       </td>\s+
       <td>\s+
       </td>\s+
       <td>2</td>\s+
       <td>Y</td>\s+
       <td>whatever</td>}msx
);
$mech->content_like( qr{<title>Flight 8, English Pale Ale</title>} );

# test assignment
$mech->submit_form_ok( {
    with_fields => { assign => ['judge-2_session-3', 3] },
} );
$mech->content_like(
    qr{<a\ href="\d+">\s+
       Mayers,\ Liam\s+
       </a>\s+
       </td>\s+
       <td>Novice</td>\s+
       <td>\s+
       </td>\s+
       <td>\s+
       </td>\s+
       <td>\s+
       <input\ name="unassign"\s+
               type="checkbox"\s+
               value="judge-2_session-3"\ />\s+
       </td>\s+
       <td>2</td>\s+
       <td>Y</td>\s+
       <td>whatever</td>}msx
);
$mech->content_unlike(
    qr{<a\ href="\d+">\s+
       Mayers,\ Liam\s+
       </a>\s+
       </td>\s+
       <td>Novice</td>\s+
       <td>\s+
       <input\ name="assign"\s+
               type="checkbox"\s+
               value="judge-2_session-1"\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="assign"\s+
               type="checkbox"\s+
               value="judge-2_session-2"\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="assign"\s+
               type="checkbox"\s+
               value="judge-2_session-3"\ />\s+
       </td>\s+
       <td>2</td>\s+
       <td>Y</td>\s+
       <td>whatever</td>}msx
);

# test unassignment
$mech->submit_form_ok( { with_fields => { unassign => 'judge-2_session-3' } } );
$mech->content_like(
    qr{<a\ href="\d+">\s+
       Mayers,\ Liam\s+
       </a>\s+
       </td>\s+
       <td>Novice</td>\s+
       <td>\s+
       <input\ name="assign"\s+
               type="checkbox"\s+
               value="judge-2_session-1"\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="assign"\s+
               type="checkbox"\s+
               value="judge-2_session-2"\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="assign"\s+
               type="checkbox"\s+
               value="judge-2_session-3"\ />\s+
       </td>\s+
       <td>2</td>\s+
       <td>Y</td>\s+
       <td>whatever</td>}msx
);
$mech->content_unlike(
    qr{<a\ href="\d+">\s+
       Mayers,\ Liam\s+
       </a>\s+
       </td>\s+
       <td>Novice</td>\s+
       <td>\s+</td>\s+
       <td>\s+</td>\s+
       <td>\s+
       <input\ name="unassign"\s+
               type="checkbox"\s+
               value="judge-2_session-3"\ />\s+
       </td>\s+
       <td>2</td>\s+
       <td>Y</td>\s+
       <td>whatever</td>}msx
);
