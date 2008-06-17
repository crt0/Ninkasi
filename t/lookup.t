#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;

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

my $lookup_url = "$url_base/cgi-bin/view/judge/";
$mech->get_ok($lookup_url);

# $mech->content_like(<<'EOF');
# <td><a href="judge-lookup/judge/">Korty, Andrew</a></td>
# <td>Certified</td>
# <td>Z9998</td>
# <td>10</td>
# <td></td>
# <td>2</td>
# <td>1, 3, 4, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16, 17, 18, 19, 23</td>
# <td>20</td>
# <td>8, 10, 15, 20</td>
# <td>20</td>
# EOF
