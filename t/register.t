#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 136;

use Apache::TestConfig;
use Ninkasi::Constraint;
use Ninkasi::Judge;
use Ninkasi::Register;
use Ninkasi::Table;
use Test::WWW::Mechanize;

Ninkasi::Table->initialize_database( { unlink => 1 } );

my $config = Apache::TestConfig->new();
my $url_base = join '', $config->{vars}{scheme}, '://', $config->hostport();
my $form_url = "$url_base/register";

my $judge = Ninkasi::Judge->new();
ok $judge;

my $rowid = $judge->add( {
        address             => '123 Fake Street',
        bjcp_id             => 'Z9988',
        city                => 'Springfield',
        competitions_judged => 10,
        email1              => 'ninkasi@ajk.name',
        email2              => 'ninkasi@ajk.name',
        first_name          => 'Lance',
        session1            => 1,
        session3            => 1,
        last_name           => 'Uppercut',
        phone_day           => '123-456-7890',
        phone_evening       => '123-456-7890',
        rank                => 50,
        state               => '--',
        submit              => 1,
        zip                 => '12345',
} );
is $rowid, 1;

my $assignment = Ninkasi::Assignment->new();
ok $assignment;

ok $assignment->add( {flight => 0, session => 1, judge => 1} );
ok $assignment->add( {flight => 0, session => 3, judge => 1} );

my $mech = Test::WWW::Mechanize->new();
$mech->get_ok($form_url);
$mech->content_contains( 'Experienced but not in the BJCP',
                         'BJCP rank description' );

$mech->submit_form_ok( { with_fields => { first_name => 'Andrew' } } );

$mech->content_contains( '<div class="error">', 'error <div>' );
$mech->content_contains( 'Looks like you left', 'blank field error message' );

## test complete & correct input

$mech->submit_form_ok( {
    with_fields => {
        address             => '123 Fake Street',
        bjcp_id             => 'Z9999',
        category01          => 'whatever',
        category02          => 'prefer',
        category03          => 'whatever',
        category04          => 'whatever',
        category05          => 'whatever',
        category06          => 'whatever',
        category07          => 'whatever',
        category08          => 'entry',
        category09          => 'whatever',
        category10          => 'entry',
        category11          => 'whatever',
        category12          => 'whatever',
        category13          => 'whatever',
        category14          => 'whatever',
        category15          => 'entry',
        category16          => 'whatever',
        category17          => 'whatever',
        category18          => 'whatever',
        category19          => 'whatever',
        category20          => 'prefer not',
        category21          => 'entry',
        category22          => 'whatever',
        category23          => 'whatever',
        category24          => 'prefer',
        city                => 'Springfield',
        competitions_judged => 10,
        email1              => 'ninkasi@ajk.name',
        email2              => 'ninkasi@ajk.name',
        first_name          => 'Andrew',
        session1            => 1,
        session3            => 1,
        last_name           => 'Korty',
        phone_day           => '123-456-7890',
        phone_evening       => '123-456-7890',
        rank                => 50,
        state               => '--',
        zip                 => '12345',
    },
} );

if ( !$mech->content_lacks( '<div class="error">', 'error <div>' ) ) {
    $mech->content() =~ /<div class="error">([^<]*)/s;
    warn $1;
}

$mech->content_is( <<'EOF', 'header' );
<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE html
     PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<link href="/ninkasi.css" rel="stylesheet" type="text/css" />
<title>Brewers&#8217; Cup Volunteer Registration Confirmation</title>
</head>
<body>
<div id="masthead">
<h1><a href="/">The Brewers&#8217; Cup Competition</a></h1>
<h2><a href="http://www.in.gov/statefair/">Indiana State Fair</a></h2>
</div>
<div id="navigation_bar_horizontal">
<a accesskey="h" href="/">Home</a>
| <a accesskey="e" href="/enter">Enter</a>
| <a accesskey="j" href="/judge">Judge</a>
| <a accesskey="m" href="/maps">Maps</a>
| <a accesskey="r" href="/results">Results</a>
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
<div id="body_text">
<h2>Thank you, Andrew!</h2>
<p>
You&#8217;ve agreed to volunteer for the following flight(s)
at the Indiana State Fair Brewers&#8217; Cup:
</p>
<ul>
<li>Friday, July 8, starting at 6 pm</li>
<li>Saturday, July 9, starting at noon</li>
</ul>
<p>
Please refer to <a href="http://brewerscup.org/">the Brewers&#8217; Cup web site</a>
for up-to-the-minute information on the competition.  Thanks!
</p></div>
</body>
</html>
EOF

# test log file
open LOG, 't/log' or die "t/log: $!";
my ($last_line);
while (my $line = <LOG>) {
    $last_line = $line;
}
like $last_line, qr/
                     address             = 123\ Fake\ Street  :
                     bjcp_id             = Z9999              :
                     category01          = whatever           :
                     category02          = prefer             :
                     category03          = whatever           :
                     category04          = whatever           :
                     category05          = whatever           :
                     category06          = whatever           :
                     category07          = whatever           :
                     category08          = entry              :
                     category09          = whatever           :
                     category10          = entry              :
                     category11          = whatever           :
                     category12          = whatever           :
                     category13          = whatever           :
                     category14          = whatever           :
                     category15          = entry              :
                     category16          = whatever           :
                     category17          = whatever           :
                     category18          = whatever           :
                     category19          = whatever           :
                     category20          = prefer\ not        :
                     category21          = entry              :
                     category22          = whatever           :
                     category23          = whatever           :
                     category24          = prefer             :
                     city                = Springfield        :
                     competitions_judged = 10                 :
                     email1              = ninkasi\@ajk\.name :
                     email2              = ninkasi\@ajk\.name :
                     first_name          = Andrew             :
                     last_name           = Korty              :
                     phone_day           = 123-456-7890       :
                     phone_evening       = 123-456-7890       :
                     rank                = 50                 :
                     session1            = 1                  :
                     session3            = 1                  :
                     state               = --                 :
                     zip                 = 12345
                 /msx;

$mech->back();

## test incorrect form submission

# submit form that is complete but with differing e-mail addresses
$mech->submit_form_ok( {
    with_fields => {
        address             => '123 Fake Street',
        bjcp_id             => 'Z9999',
        category01          => 'whatever',
        category02          => 'prefer',
        category03          => 'whatever',
        category04          => 'whatever',
        category05          => 'whatever',
        category06          => 'whatever',
        category07          => 'whatever',
        category08          => 'entry',
        category09          => 'whatever',
        category10          => 'entry',
        category11          => 'whatever',
        category12          => 'whatever',
        category13          => 'whatever',
        category14          => 'whatever',
        category15          => 'entry',
        category16          => 'whatever',
        category17          => 'whatever',
        category18          => 'whatever',
        category19          => 'whatever',
        category20          => 'prefer not',
        category21          => 'entry',
        category22          => 'whatever',
        category23          => 'whatever',
        category24          => 'prefer',
        city                => 'Springfield',
        competitions_judged => 10,
        email1              => 'ninkasi@ajk.name',
        email2              => 'Xninkasi@ajk.name',
        first_name          => 'Andrew',
        session1            => 1,
        session3            => 1,
        last_name           => 'Korty',
        phone_day           => '123-456-7890',
        phone_evening       => '123-456-7890',
        rank                => 50,
        state               => '--',
        zip                 => '12345',
    },
} );

# test the filled in fields
$mech->content_like(qr{name="address"\s+
                       size="\d+"\s+
                       value="123\ Fake\ Street"}msx, 'address');
$mech->content_like(qr{name="bjcp_id"\s+
                       size="\d+"\s+
                       value="Z9999"}msx, 'BJCP id');
$mech->content_like(qr{checked="checked"\s+
                       name="category01"\s+
                       type="radio"\s+
                       value="whatever"}msx, 'category 1 checked');
$mech->content_like(qr{checked="checked"\s+
                       name="category02"\s+
                       type="radio"\s+
                       value="prefer"}msx, 'category 2 checked');
$mech->content_like(qr{checked="checked"\s+
                       name="category08"\s+
                       type="radio"\s+
                       value="entry"}msx, 'category 8 checked');
$mech->content_like(qr{checked="checked"\s+
                       name="category10"\s+
                       type="radio"\s+
                       value="entry"}msx, 'category 10 checked');
$mech->content_like(qr{checked="checked"\s+
                       name="category15"\s+
                       type="radio"\s+
                       value="entry"}msx, 'category 15 checked');
$mech->content_like(qr{checked="checked"\s+
                       name="category20"\s+
                       type="radio"\s+
                       value="prefer\ not"}msx, 'category 20 checked');
$mech->content_like(qr{checked="checked"\s+
                       name="category21"\s+
                       type="radio"\s+
                       value="entry"}msx, 'category 21 checked');
$mech->content_like(qr{checked="checked"\s+
                       name="category24"\s+
                       type="radio"\s+
                       value="prefer"}msx, 'category 24 checked');
$mech->content_like(qr{name="city"\s+
                       size="\d+"\s+
                       value="Springfield"}msx, 'city');
$mech->content_like(qr{name="competitions_judged"\s+
                       size="\d+"\s+
                       value="10"}msx, 'competitions judged');
$mech->content_like(qr{<span\ class="field_marker">\*\ </span>\s+
                       <input\s+
                       type="text"\s+
                       name="email1"\s+
                       size="\d+"\s+
                       value="ninkasi\@ajk\.name"}msx, 'e-mail');
$mech->content_like(qr{<span\ class="field_marker">\*\ </span>\s+
                       <input\s+
                       type="text"\s+
                       name="email2"\s+
                       size="\d+"\s+
                       value="Xninkasi\@ajk\.name"}msx, 'e-mail confirmation');
$mech->content_like(qr{name="first_name"\s+
                       size="\d+"\s+
                       value="Andrew"}msx, 'first name');
$mech->content_like(qr{name="last_name"\s+
                       size="\d+"\s+
                       value="Korty"}msx, 'last name');
$mech->content_like(qr{checked="checked"\s+
                       name="session1"\s+
                       type="checkbox"\s+
                       value="1"}msx, 'session 1 checked');
$mech->content_like(qr{name="session2"\s+
                       type="checkbox"\s+
                       value="1"}msx, 'session 2 unchecked');
$mech->content_like(qr{checked="checked"\s+
                       name="session3"\s+
                       type="checkbox"\s+
                       value="1"}msx, 'session 3 checked');
$mech->content_like(qr{name="phone_day"\s+
                       size="\d+"\s+
                       value="123-456-7890"}msx, 'daytime phone');
$mech->content_like(qr{name="phone_evening"\s+
                       size="\d+"\s+
                       value="123-456-7890"}msx, 'evening phone');
$mech->content_like(qr{selected="selected"\s+
                       value="50"}msx, '50 competitions judged');
$mech->content_like(qr{selected="selected"\s+
                       value="--"}msx, 'no state specified');
$mech->content_like(qr{name="zip"\s+
                       size="\d+"\s+
                       value="12345"}msx, 'zip code');

# test table names in class data
is(Ninkasi::Constraint->Table_Name(), 'constraint' );
is(Ninkasi::Volunteer ->Table_Name(), 'volunteer'  );

my ($sth, $result) = $judge->bind_hash(
    {
        columns     => [ qw/address bjcp_id city competitions_judged email
                            first_name rowid last_name phone_day phone_evening
                            rank state zip/ ],
        where       => 'email = ?',
        bind_values => [ qw/ninkasi@ajk.name/ ],
    }
);

ok $sth->fetch();

my $judge_id = $result->{rowid};
ok $judge_id;

is $result->{ address             }, '123 Fake Street'  ;
is $result->{ bjcp_id             }, 'Z9999'            ;
is $result->{ city                }, 'Springfield'      ;
is $result->{ competitions_judged }, 10                 ;
is $result->{ email               }, 'ninkasi@ajk.name' ;
is $result->{ first_name          }, 'Andrew'           ;
is $result->{ last_name           }, 'Korty'            ;
is $result->{ phone_day           }, '123-456-7890'     ;
is $result->{ phone_evening       }, '123-456-7890'     ;
is $result->{ rank                }, 50                 ;
is $result->{ state               }, '--'               ;
is $result->{ zip                 }, 12345              ;

($sth, $result) = $assignment->bind_hash( {
    bind_values => [$judge_id],
    columns     => [qw/flight session/],
    order       => 'session',
    where       => 'volunteer = ?',
} );

ok $sth->fetch();
is $result->{session}, 1;
is $result->{flight }, 0;

ok $sth->fetch();
is $result->{session}, 3;
is $result->{flight }, 0;

ok !$sth->fetch();

my $constraint = Ninkasi::Constraint->new();
ok $constraint;
($sth, $result) = $constraint->bind_hash(
    {
        columns     => [ qw/category rowid type volunteer/ ],
        where       => 'volunteer = ?',
        bind_values => [ $judge_id ],
    }
);

my $prefer     = $Ninkasi::Constraint::NUMBER{ prefer       };
my $whatever   = $Ninkasi::Constraint::NUMBER{ whatever     };
my $prefer_not = $Ninkasi::Constraint::NUMBER{ 'prefer not' };
my $entry      = $Ninkasi::Constraint::NUMBER{ entry        };

my %expected_constraint = (
     1 => $whatever   ,
     2 => $prefer     ,
     3 => $whatever   ,
     4 => $whatever   ,
     5 => $whatever   ,
     6 => $whatever   ,
     7 => $whatever   ,
     8 => $entry      ,
     9 => $whatever   ,
    10 => $entry      ,
    11 => $whatever   ,
    12 => $whatever   ,
    13 => $whatever   ,
    14 => $whatever   ,
    15 => $entry      ,
    16 => $whatever   ,
    17 => $whatever   ,
    18 => $whatever   ,
    19 => $whatever   ,
    20 => $prefer_not ,
    21 => $entry      ,
    22 => $whatever   ,
    23 => $whatever   ,
    24 => $prefer     ,
);

my $rows_fetched = 0;
while ( $sth->fetch() ) {
    is $result->{type}, $expected_constraint{ $result->{category} };
    is $result->{volunteer}, $judge_id;
    ok $result->{rowid} > 0;
    ++$rows_fetched;
}

is $rows_fetched, scalar keys %expected_constraint, 'number of constraints';
