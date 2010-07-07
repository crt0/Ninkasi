#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 74;

use Apache::TestConfig;
use IPC::Open2;
use Ninkasi::Table;
use Test::WWW::Mechanize;

my $test_config = Apache::TestConfig->new();
my $url_base = join '', $test_config->{vars}{scheme}, '://',
                        $test_config->hostport();

my $dbh = Ninkasi::Table->new()->Database_Handle();
eval {
    $dbh->{PrintError} = 0;
    $dbh->do('DELETE FROM judge'       );
    $dbh->do("DELETE FROM 'constraint'");
    $dbh->do("DELETE FROM assignment");
    $dbh->do("DELETE FROM flight");
    $dbh->{PrintError} = 1;
};

my $mech = Test::WWW::Mechanize->new();

# with no flights configured yet, looking for one should cause a 404
my $lookup_url = "$url_base/manage/assignment/08";
$mech->get($lookup_url);
is $mech->status(), 404;
$mech->content_like( qr{<title>Flight 08 Not Found</title>},
                     'Flight 08 404 title' );
$mech->content_like( qr/Flight 08 not found\./, 'Flight 08 404 content' );

# test empty flight table
$lookup_url = "$url_base/manage/flight/";
$mech->get_ok($lookup_url);
$mech->content_like(
    qr{<tr\ class="odd">\s+
       <td>\s+
       <input\ name="number_1"\s+
               size="10"\s+
               value=""\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="category_1"\s+
               size="10"\s+
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
       <td>\s+
       </td>\s+
       </tr>}msx,
    'empty flight table',
);

# adding flights with duplicate numbers should fail
$mech->submit_form_ok( {
    button => 'save',
    with_fields => {
        number_1      => 1,
        category_1    => 1,
        description_1 => 'Light Lager',
        number_2      => 1,
        category_2    => 1,
        description_2 => 'Light Lager Duplicate',
    }
} );
$mech->content_contains( '<div class="error">', 'error <div>' );
$mech->content_contains( 'Flight names must be unique.',
                         'flight name uniqueness error' );
$mech->content_like(
    qr{<tr\ class="odd">\s+
       <td>\s+
       <span\ class="error">\*</span>\s+
       <input\ name="number_1"\s+
               size="10"\s+
               value="1"\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="category_1"\s+
               size="10"\s+
               value="1"\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="pro_1"\s+
               type="checkbox"\s+
               value="1"\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="description_1"\s+
               size="40"\s+
               value="Light\ Lager"\ />\s+
       </td>\s+
       <td>\s+
       <a\ href="/manage/assignment/1">view</a>\s+
       </td>\s+
       </tr>}msx,
    'fields in flight table after error',
);

# add flights
my %data = (
    category    => [ 2, 8, 10, 14,    14,    15, 20 ],
    number      => [ qw/02 08 10 14b 14a 15 20/ ],
    pro         => [ undef, 1, (undef) x 5 ],
    description => [
        'Pilsner',
        'English Pale Ale',
        'American Ale',
        'India Pale Ale, Table B',
        'India Pale Ale, Table A',
        'German Wheat and Rye Beer',
        'Fruit Beer',
    ],
);
my %input = ();
foreach my $row ( 1 .. 7 ) {
    while ( my ( $name, $value ) = each %data ) {
        $input{ "${name}_$row" } = $value->[ $row - 1 ];
    }
}
$mech->submit_form_ok( { button => 'save', with_fields => \%input } );
$mech->content_like(
    qr{<tr\ class="odd">\s+
       <td>\s+
       <input\ name="number_5"\s+
               size="10"\s+
               value="14b"\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="category_5"\s+
               size="10"\s+
               value="14"\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="pro_5"\s+
               type="checkbox"\s+
               value="1"\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="description_5"\s+
               size="40"\s+
               value="India\ Pale\ Ale,\ Table\ B"\ />\s+
       </td>\s+
       <td>\s+
       <a\ href="/manage/assignment/14b">view</a>\s+
       </td>\s+
       </tr>}msx,
    'flight 14b got added',
);
$mech->content_like(
    qr{<tr\ class="even">\s+
       <td>\s+
       <input\ name="number_2"\s+
               size="10"\s+
               value="08"\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="category_2"\s+
               size="10"\s+
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
       <td>\s+
       <a\ href="/manage/assignment/08">view</a>\s+
       </td>\s+
       </tr>}msx,
    'flight 08 got added',
);

# add another row
$mech->submit_form_ok( {
    button      => 'save',
    with_fields => {
        number_8      => 21,
        category_8    => 21,
        description_8 => 'Spice/Herb/Vegetable Beer',
    }
} );
$mech->content_like(
    qr{<tr\ class="even">\s+
       <td>\s+
       <input\ name="number_8"\s+
               size="10"\s+
               value="21"\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="category_8"\s+
               size="10"\s+
               value="21"\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="pro_8"\s+
               type="checkbox"\s+
               value="1"\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="description_8"\s+
               size="40"\s+
               value="Spice/Herb/Vegetable\ Beer"\ />\s+
       </td>\s+
       <td>\s+
       <a\ href="/manage/assignment/21">view</a>\s+
       </td>\s+
       </tr>}msx,
    'flight 21 got added',
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
        pro_brewer          => 1,
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
        category14          => 'prefer not',
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
    qr{<a\ href="/manage/judge/\d+">\s+
       \|&lt;iefer,\ Angelina\s+
       </a>\s+
       </td>\s+
       <td>Certified</td>\s+
       <td></td>\s+
       <td>N/A</td>\s+
       <td></td>\s+
       <td>10</td>\s+
       <td>N</td>\s+
       <td><a\ href="/manage/assignment/10">10</a>,\s+
       <a\ href="/manage/assignment/15">15</a>,\s+
       <a\ href="/manage/assignment/21">21</a></td>\s+
       <td><a\ href="/manage/assignment/20">20</a></td>\s+
       <td><a\ href="/manage/assignment/08">08</a>,\s+
       <a\ href="/manage/assignment/14a">14a</a>,\s+
       <a\ href="/manage/assignment/14b">14b</a></td>\s+
       <td><a\ href="/manage/assignment/02">02</a></td>}msx,
    'judge view',
);
$mech->content_like( qr{<title>Registered Judges</title>}, 'judge view title' );
$mech->html_lint_ok('HTML validation');

# test CSV format for view of all judges
$mech->follow_link_ok( { text_regex => qr/csv/ } );
is $mech->ct(), 'text/plain';
$mech->content_is( <<EOF, 'CSV judge view' );
"Name","Rank","Fri. PM","Sat. AM","Sat. PM","Comps Judged","Pro Brewer?","Entries","Prefers Not","Whatever","Prefers"
"Carrera, Lyndsey","Certified","","N/A","","10","N","10, 15, 21","14a, 14b, 20","08","02"
"Mayers, Liam","Novice","","","","2","Y","","","02, 08, 10, 14a, 14b, 15, 20, 21",""
"Reynoso, Greggory","Certified","","N/A","","10","Y","08","20","10, 14a, 14b, 15, 21","02"
"Underhill, Leann","Certified","","","N/A","10","N","10, 15","20","08","02, 14a, 14b, 21"
"|<iefer, Angelina","Certified","","N/A","","10","N","10, 15, 21","20","08, 14a, 14b","02"
EOF

# test roster
$mech->back();
$mech->follow_link_ok( { text_regex => qr/roster/ } );
is $mech->ct(), 'application/pdf';
my $file_pid = IPC::Open2::open2 my $file_reader, my $file_writer, qw/file -/;
print $file_writer $mech->content();
close $file_writer;
like <$file_reader>, qr/PDF/;
close $file_reader;

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
                       </tr>}msx,
                'individual judge view');
$mech->content_like( qr{<title>Liam Mayers</title>},
                     'individual judge view title' );

# test view of individual judge information with html encoding
$mech->back();
$mech->follow_link_ok( { text_regex => qr/iefer, Angelina/ } );
$mech->content_like( qr{<h2>Angelina |&lt;iefer</h2>},
                     'HTML-encoded judge view' );
$mech->content_like( qr{<title>Angelina \|&lt;iefer</title>},
                     'HTML-encoded judge view title' );

# test category view
$lookup_url = "$url_base/manage/assignment/08";
$mech->get_ok($lookup_url);
$mech->content_like(
    qr{<a\ href="/manage/judge/\d+">\s+
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
       <td>whatever</td>}msx,
    'flight 08 assignment view',
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
       <td>whatever</td>}msx,
    'pro judge ineligible for flight 08',
);
$mech->content_lacks( 'Reynoso, Greggory',
                      'pro judge ineligible for flight 08' );
$mech->content_like( qr{<title>Flight 08, English Pale Ale</title>},
                     'flight 08 assignment view title' );

# test judge link
$mech->follow_link_ok( { text_regex => qr/Mayers, Liam/ } );
$mech->content_like( qr{<h2>Liam Mayers</h2>},
                     'individual judge view heading' );
$mech->content_like( qr{<title>Liam Mayers</title>},
                     'individual judge view title' );
$mech->back();

# test assignment
$mech->form_number(2);
$mech->tick( assign => 'judge-2_session-3', 1 );
$mech->tick( assign => 'judge-4_session-3', 1 );
$mech->submit_form_ok();
$mech->content_like(
    qr{<a\ href="/manage/judge/\d+">\s+
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
       <td>whatever</td>}msx,
    'assigned judge moved to top',
);
$mech->content_like(
    qr{<a\ href="/manage/judge/\d+">\s+
       \|&lt;iefer,\ Angelina\s+
       </a>\s+
       </td>\s+
       <td>Certified</td>\s+
       <td>\s+
       </td>\s+
       <td>\s+
       N/A</td>\s+
       <td>\s+
       <input\ name="unassign"\s+
               type="checkbox"\s+
               value="judge-4_session-3"\ />\s+
       </td>\s+
       <td>10</td>\s+
       <td>N</td>\s+
       <td>whatever</td>}msx,
    'assigned judge moved to top',
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
       <td>whatever</td>}msx,
    "assigned judge didn't stay on bottom",
);

# test unassignment
$mech->tick( unassign => 'judge-2_session-3', 1 );
$mech->submit_form_ok();
$mech->content_like(
    qr{<a\ href="/manage/judge/\d+">\s+
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
       <td>whatever</td>}msx,
    'unassigned judge moved to bottom',
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
       <td>whatever</td>}msx,
    "unassigned judge didn't stay at top",
);

# test table card (just make sure it's a PDF)
$mech->back();
$mech->follow_link_ok( { text_regex => qr/card/ } );
is $mech->ct(), 'application/pdf';
($file_pid, $file_reader, $file_writer) = ();
$file_pid = IPC::Open2::open2 $file_reader, $file_writer, qw/file -/;
print $file_writer $mech->content();
close $file_writer;
like <$file_reader>, qr/PDF/;
close $file_reader;

# test ordering by preference
$lookup_url = "$url_base/manage/assignment/14a";
$mech->get_ok($lookup_url);
$mech->content_like( qr{Underhill.*Reynoso.*Carrera}msx,
                     '"prefer" precedes "whatever" precedes "prefer not"' );

# add flights with multiple categories
$lookup_url = "$url_base/manage/flight/";
$mech->get_ok($lookup_url);
$mech->submit_form_ok( {
    button => 'save',
    with_fields => {
        category_9    => '20, 21',
        number_9      => 26,
        description_9 => 'Fruit Beer / SHV',
    },
} );
$mech->content_like(
    qr{<tr\ class="odd">\s+
       <td>\s+
       <input\ name="number_9"\s+
               size="10"\s+
               value="26"\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="category_9"\s+
               size="10"\s+
               value="20\ 21"\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="pro_9"\s+
               type="checkbox"\s+
               value="1"\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="description_9"\s+
               size="40"\s+
               value="Fruit\ Beer\ /\ SHV"\ />\s+
       </td>\s+
       <td>\s+
       <a\ href="/manage/assignment/26">view</a>\s+
       </td>\s+
       </tr>}msx,
       'flight with multiple categories',
);

# check assignments page for Fruit Beer / SHV flight
$lookup_url = "$url_base/manage/assignment/26";
$mech->get_ok($lookup_url);
$mech->content_like(
    qr{<a\ href="/manage/judge/\d+">\s+
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
       <td>whatever</td>}msx,
    'available judge on flight 26',
);
$mech->content_like(
    qr{<a\ href="/manage/judge/\d+">\s+
       Underhill,\ Leann\s+
       </a>\s+
       </td>\s+
       <td>Certified</td>\s+
       <td>\s+
       <input\ name="assign"\s+
               type="checkbox"\s+
               value="judge-1_session-1"\ />\s+
       </td>\s+
       <td>\s+
       <input\ name="assign"\s+
               type="checkbox"\s+
               value="judge-1_session-2"\ />\s+
       </td>\s+
       <td>\s+
       N/A</td>\s+
       <td>10</td>\s+
       <td>N</td>\s+
       <td>prefer\ not</td>}msx,
    'available judge on flight 26',
);
$mech->content_lacks( 'Carrera', 'homebrewer ineligible to judge flight 26' );

# test assignment of a multi-category flight
$mech->form_number(2);
$mech->tick( assign => 'judge-2_session-1', 1 );
$mech->submit_form_ok();
$mech->content_like(
    qr{<a\ href="/manage/judge/\d+">\s+
       Mayers,\ Liam\s+
       </a>\s+
       </td>\s+
       <td>Novice</td>\s+
       <td>\s+
       <input\ name="unassign"\s+
               type="checkbox"\s+
               value="judge-2_session-1"\ />\s+
       </td>\s+
       <td>\s+
       </td>\s+
       <td>\s+
       </td>\s+
       <td>2</td>\s+
       <td>Y</td>\s+
       <td>whatever</td>}msx,
    'assigned judge moved to top',
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
       <td>whatever</td>}msx,
    "assigned judge didn't stay on bottom",
);
$mech->content_unlike( qr{Mayers,\ Liam.*Mayers,\ Liam}msx,
                       'assigned judge not duplicated' );

# test unassignment in a multi-category flight
$mech->tick( unassign => 'judge-2_session-1', 1 );
$mech->submit_form_ok();
$mech->content_like(
    qr{<a\ href="/manage/judge/\d+">\s+
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
       <td>whatever</td>}msx,
    'unassigned judge moved to bottom',
);
$mech->content_unlike(
    qr{<a\ href="\d+">\s+
       Mayers,\ Liam\s+
       </a>\s+
       </td>\s+
       <td>Novice</td>\s+
       <td>\s+
       <input\ name="unassign"\s+
               type="checkbox"\s+
               value="judge-2_session-3"\ />\s+
       </td>\s+
       <td>\s+
       </td>\s+
       <td>\s+
       </td>\s+
       <td>2</td>\s+
       <td>Y</td>\s+
       <td>whatever</td>}msx,
    "unassigned judge didn't stay at top",
);
