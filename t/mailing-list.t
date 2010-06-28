#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 16;

use Apache::TestConfig;
use Ninkasi::Table;
use Test::WWW::Mechanize;

my $test_config = Apache::TestConfig->new();
my $url_base = join '', $test_config->{vars}{scheme}, '://',
                        $test_config->hostport();

my $dbh = Ninkasi::Table->new()->Database_Handle();
eval {
    $dbh->{PrintError} = 0;
    $dbh->do('DELETE FROM newsletter');
    $dbh->{PrintError} = 1;
};

my $mech = Test::WWW::Mechanize->new( cookie_jar => undef );

$mech->get_ok("$url_base/newsletter");

# test bad format
$mech->submit_form_ok( {
    with_fields => {
        email_1 => 'a',
        email_2 => 'a',
    },
} );
$mech->content_contains('<div class="error">');
$mech->content_contains("We don't recognize the format of your e-mail address.");

# test unmatched addresses
$mech->submit_form_ok( {
    with_fields => {
        email_1 => 'a@b.c',
        email_2 => 'd@b.c',
    },
} );
$mech->content_contains('<div class="error">');
$mech->content_contains('e-mail addresses did not match.');

# test matching addresses in correct format
$mech->submit_form_ok( {
    with_fields => {
        email_1 => 'a@b.c',
        email_2 => 'a@b.c',
    },
} );
$mech->content_contains('Your e-mail address was stored successfully.');

# shouldn't be an error to resubmit the same address
$mech->submit_form_ok( {
    with_fields => {
        email_1 => 'a@b.c',
        email_2 => 'a@b.c',
    },
} );
$mech->content_contains('Your e-mail address was stored successfully.');

# check management page for correct addresses
$mech->get_ok('/manage/mailing_list');
$mech->content_lacks('<li>a</li>');
$mech->content_lacks('<li>a@b</li>');
$mech->content_lacks('<li>d@b.c</li>');
$mech->content_contains('<li>a@b.c</li>');

