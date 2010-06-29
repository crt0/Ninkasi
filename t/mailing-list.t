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
$mech->content_contains( '<div class="error">', 'error <div>' );
$mech->content_contains( "We don't recognize the format of your e-mail "
                         . "address.", 'e-mail format error message' );

# test unmatched addresses
$mech->submit_form_ok( {
    with_fields => {
        email_1 => 'a@b.c',
        email_2 => 'd@b.c',
    },
} );
$mech->content_contains( '<div class="error">', 'error <div>' );
$mech->content_contains( 'e-mail addresses did not match.',
                         'e-mail mismatch error message' );

# test matching addresses in correct format
$mech->submit_form_ok( {
    with_fields => {
        email_1 => 'a@b.c',
        email_2 => 'a@b.c',
    },
} );
$mech->content_contains( 'Your e-mail address was stored successfully.',
                         'e-mail success' );

# shouldn't be an error to resubmit the same address
$mech->submit_form_ok( {
    with_fields => {
        email_1 => 'a@b.c',
        email_2 => 'a@b.c',
    },
} );
$mech->content_contains( 'Your e-mail address was stored successfully.',
                         'e-mail success' );

# check management page for correct addresses
$mech->get_ok('/manage/mailing_list');
$mech->content_lacks( '<li>a</li>', '<a> did not succeed' );
$mech->content_lacks( '<li>a@b</li>', '<a@b> did not succeed' );
$mech->content_lacks( '<li>d@b.c</li>', 'mismatched <d@b.c> did not succeed' );
$mech->content_contains('<li>a@b.c</li>', '<a@b.c> succeeded' );

