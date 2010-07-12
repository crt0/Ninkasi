#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 44;

use Apache::TestConfig;
use Test::WWW::Mechanize;

sub header_ok {
    my ($mech, $title) = @_;

    $mech->content_contains(<<EOF, "header of $title");
<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE html
     PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<link href="/ninkasi.css" rel="stylesheet" type="text/css" />
<title>$title</title>
</head>
<body>
<div id="masthead">
<h1><a href="/">The Brewers&#8217; Cup Competition</a></h1>
<h2><a href="http://www.in.gov/statefair/">Indiana State Fair</a></h2>
</div>
EOF
}

sub header_transitional_ok {
    my ($mech, $title) = @_;

    $mech->content_contains(<<EOF, "header of $title");
<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE html
     PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<link href="ninkasi.css" rel="stylesheet" type="text/css" />
<title>$title</title>
</head>
<body>
<div id="masthead">
<h1><a href="/">The Brewers&#8217; Cup Competition</a></h1>
<h2><a href="http://www.in.gov/statefair/">Indiana State Fair</a></h2>
</div>
EOF
}

sub navbar_ok {
    my ($mech) = @_;

    $mech->content_contains(<<EOF, 'navbar');
<div id="navigation_bar_horizontal">
<a accesskey="h" href="/">Home</a>
| <a accesskey="e" href="/enter">Enter</a>
| <a accesskey="j" href="/judge">Judge</a>
| <a accesskey="m" href="/maps">Maps</a>
| <a accesskey="r" href="/results">Results</a>
| <a accesskey="n" href="/newsletter">Newsletter</a>
| <a accesskey="c" href="/contacts">Contacts</a>
</div>
<form action="http://www.google.com/cse" id="cse-search-box">
  <div>
    <input type="hidden" name="cx" value="004596647214513492520:lcp17p0a-fw" />
    <input type="hidden" name="ie" value="UTF-8" />
    <input accesskey="s" type="text" name="q" />
    <input type="submit" name="sa" value="Search" />
  </div>
</form>
<script type="text/javascript"
        src="http://www.google.com/coop/cse/brand?form=cse-search-box&amp;lang=en">
</script>
EOF
}

my $test_config = Apache::TestConfig->new();
my $url_base = join '', $test_config->{vars}{scheme}, '://',
                        $test_config->hostport();

my $mech = Test::WWW::Mechanize->new();

# suppress warnings from HTML::Form caused by broken HTML on external sites
my $html_form_warning
    = '^Use of uninitialized value in hash element at .*/HTML/Form\.pm';
my $html_pullparser_warning = 'Parsing of undecoded UTF-8 will give garbage'
    . ' when decoding entities at .*/HTML/PullParser\.pm';
$SIG{__WARN__} = sub {
    if ($_[0] !~ qr{$html_form_warning}
     && $_[0] !~ qr{$html_pullparser_warning}) {
        warn $_[0];
    }
};

$mech->get_ok($url_base);
header_ok $mech, 'The Brewers&#8217; Cup Competition';
$mech->content_contains(<<EOF, 'navigation bar');
<div id="navigation_bar_vertical">
  <div><a accesskey="e" href="enter">Submit Entries</a></div>
  <div><a accesskey="j" href="judge">Register to Judge</a></div>
  <div><a accesskey="m" href="maps">Find the Fairgrounds</a></div>
  <div><a accesskey="r" href="results">View 2010 Results</a></div>
  <div><a accesskey="n" href="newsletter">Get the Newsletter</a></div>
  <div><a accesskey="c" href="contacts">Contact Us</a></div>
  <div><form action="http://www.google.com/cse" id="cse-search-box">
  <div>
    <input type="hidden" name="cx" value="004596647214513492520:lcp17p0a-fw" />
    <input type="hidden" name="ie" value="UTF-8" />
    <input accesskey="s" type="text" name="q" />
    <input type="submit" name="sa" value="Search" />
  </div>
</form>
<script type="text/javascript"
        src="http://www.google.com/coop/cse/brand?form=cse-search-box&amp;lang=en">
</script>
</div>
EOF
$mech->html_lint_ok('HTML validation');
$mech->page_links_ok('check all links');
$mech->get_ok("$url_base/index.html");

$mech->follow_link_ok( {text => 'Submit Entries'} );
header_ok $mech, 'Brewers&#8217; Cup Entry Forms and Guidelines';
navbar_ok $mech;
$mech->html_lint_ok('HTML validation of /enter');
$mech->page_links_ok('check all links on /enter');
$mech->get_ok("$url_base/BCupInteractiveEntryForm.pdf");
$mech->get_ok("$url_base/Entries.htm");
$mech->get_ok("$url_base/entry_form.pdf");
$mech->back();

$mech->follow_link_ok( {text => 'Judge'} );
header_transitional_ok $mech, 'Register to Judge at the Brewers&#8217; Cup';
navbar_ok $mech;
$mech->html_lint_ok('HTML validation of /judge');
$mech->page_links_ok('check all links on /judge');
$mech->get_ok("$url_base/JudgeInfo.htm");
$mech->back();

$mech->follow_link_ok( {text => 'Maps'} );
header_transitional_ok $mech, 'Directions to the Brewers&#8217; Cup';
navbar_ok $mech;
$mech->html_lint_ok('HTML validation of /maps');
$mech->page_links_ok('check all links on /maps');
$mech->get_ok("$url_base/map.htm");
$mech->back();

$mech->follow_link_ok( {text => 'Results'} );
header_ok $mech, 'Results of Past Brewers&#8217; Cup Competitions';
navbar_ok $mech;
$mech->html_lint_ok('HTML validation of /results');
$mech->links_ok([grep { $_->url() !~ m{^/photos/} } $mech->find_all_links()],
                'check non-photo links on /results');
$mech->get_ok("$url_base/Results.htm");
$mech->get_ok("$url_base/2006Results.htm");
$mech->back();

$mech->follow_link_ok( {text => 'Newsletter'} );
header_ok $mech, 'Brewers&#8217; Cup Newsletter';
navbar_ok $mech;
$mech->html_lint_ok('HTML validation of /newsletter');
$mech->page_links_ok('check all links on /newsletter');
$mech->back();

$mech->follow_link_ok( {text => 'Contacts'} );
header_ok $mech, 'Brewers&#8217; Cup Contact Information';
navbar_ok $mech;
$mech->html_lint_ok('HTML validation of /contacts');
$mech->page_links_ok('check all links on /contacts');
$mech->get_ok("$url_base/Links.htm");
$mech->back();
