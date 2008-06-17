#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 81;

use Apache::TestConfig;
use Ninkasi::Constraint;
use Ninkasi::Judge;
use Ninkasi::JudgeSignup;
use Ninkasi::Table;
use Smart::Comments;
use Test::WWW::Mechanize;

my $config = Apache::TestConfig->new();
my $url_base = join '', $config->{vars}{scheme}, '://', $config->hostport();
my $form_url = "$url_base/cgi-bin/judge-signup";

my $dbh = Ninkasi::Table->new()->Database_Handle();
eval {
    $dbh->{PrintError} = 0;
    $dbh->do('DELETE FROM judge'       );
    $dbh->do("DELETE FROM 'constraint'");
    $dbh->{PrintError} = 1;
};

my $mech = Test::WWW::Mechanize->new();
$mech->get_ok($form_url);
$mech->title_is('Brewers Cup Judge Volunteer Form');
$mech->content_contains('Experienced but not in the BJCP');

$mech->submit_form_ok( { with_fields => { first_name => 'Andrew' } } );

$mech->content_contains('<div class="error">');
$mech->content_contains('Looks like you left');

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
        flight1             => 1,
        flight3             => 1,
        last_name           => 'Korty',
        phone_day           => '123-456-7890',
        phone_evening       => '123-456-7890',
        rank                => 50,
        state               => '--',
        zip                 => '12345',
    },
} );

if ( !$mech->content_lacks('<div class="error">') ) {
    $mech->content() =~ /<div class="error">([^<]*)/s;
    warn $1;
}

$mech->content_is(<<'EOF');
<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
          "http://www.w3.org/TR/html4/loose.dtd">
<html lang="en">
<head>
<link href="/css/ninkasi.css" rel="stylesheet" type="text/css">
<title>Brewers Cup Judge Volunteer Confirmation</title>
</head>
<body>
<div id="body_text">
<h2>Thank you, Andrew!</h2>
<p>
You've agreed to judge the following flight(s) at the Indiana State Fair
Brewers Cup:
</p>
<ul>
<li>Friday, July 11, starting at 6 pm</li>
<li>Saturday, July 12, starting at noon</li>
</ul>
<p>
Please refer to <a href="http://brewerscup.org/">the Brewers Cup web site</a>
for up-to-the-minute information on the competition.  Thanks!
</p>
</div>
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
                     flight1             = 1                  :
                     flight3             = 1                  :
                     last_name           = Korty              :
                     phone_day           = 123-456-7890       :
                     phone_evening       = 123-456-7890       :
                     rank                = 50                 :
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
        flight1             => 1,
        flight3             => 1,
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
                       value="123\ Fake\ Street"}msx);
$mech->content_like(qr{name="bjcp_id"\s+
                       size="\d+"\s+
                       value="Z9999"}msx);
$mech->content_like(qr{checked="checked"\s+
                       name="category01"\s+
                       type="radio"\s+
                       value="whatever"}msx);
$mech->content_like(qr{checked="checked"\s+
                       name="category02"\s+
                       type="radio"\s+
                       value="prefer"}msx);
$mech->content_like(qr{checked="checked"\s+
                       name="category08"\s+
                       type="radio"\s+
                       value="entry"}msx);
$mech->content_like(qr{checked="checked"\s+
                       name="category10"\s+
                       type="radio"\s+
                       value="entry"}msx);
$mech->content_like(qr{checked="checked"\s+
                       name="category15"\s+
                       type="radio"\s+
                       value="entry"}msx);
$mech->content_like(qr{checked="checked"\s+
                       name="category20"\s+
                       type="radio"\s+
                       value="prefer\ not"}msx);
$mech->content_like(qr{checked="checked"\s+
                       name="category21"\s+
                       type="radio"\s+
                       value="entry"}msx);
$mech->content_like(qr{checked="checked"\s+
                       name="category24"\s+
                       type="radio"\s+
                       value="prefer"}msx);
$mech->content_like(qr{name="city"\s+
                       size="\d+"\s+
                       value="Springfield"}msx);
$mech->content_like(qr{name="competitions_judged"\s+
                       size="\d+"\s+
                       value="10"}msx);
$mech->content_like(qr{<span\ class="field_marker">\*\ </span>\s+
                       <input\s+
                       type="text"\s+
                       name="email1"\s+
                       size="\d+"\s+
                       value="ninkasi\@ajk\.name"}msx);
$mech->content_like(qr{<span\ class="field_marker">\*\ </span>\s+
                       <input\s+
                       type="text"\s+
                       name="email2"\s+
                       size="\d+"\s+
                       value="Xninkasi\@ajk\.name"}msx);
$mech->content_like(qr{name="first_name"\s+
                       size="\d+"\s+
                       value="Andrew"}msx);
$mech->content_like(qr{name="last_name"\s+
                       size="\d+"\s+
                       value="Korty"}msx);
$mech->content_like(qr{checked="checked"\s+
                       name="flight1"\s+
                       type="checkbox"\s+
                       value="1"}msx);
$mech->content_like(qr{name="flight2"\s+
                       type="checkbox"\s+
                       value="1"}msx);
$mech->content_like(qr{checked="checked"\s+
                       name="flight3"\s+
                       type="checkbox"\s+
                       value="1"}msx);
$mech->content_like(qr{name="phone_day"\s+
                       size="\d+"\s+
                       value="123-456-7890"}msx);
$mech->content_like(qr{name="phone_evening"\s+
                       size="\d+"\s+
                       value="123-456-7890"}msx);
$mech->content_like(qr{selected="selected"\s+
                       value="50"}msx);
$mech->content_like(qr{selected="selected"\s+
                       value="--"}msx);
$mech->content_like(qr{name="zip"\s+
                       size="\d+"\s+
                       value="12345"}msx);

# test table names in class data
is(Ninkasi::Judge->Table_Name(),      'judge'     );
is(Ninkasi::Constraint->Table_Name(), 'constraint');

my $judge = Ninkasi::Judge->new();
ok $judge;

my ($sth, $result) = $judge->bind_hash(
    {
        columns     => [ qw/address bjcp_id city competitions_judged email
                            first_name flight1 flight2 flight3 judge_id
                            last_name phone_day phone_evening rank state
                            zip/ ],
        where       => 'email = ?',
        bind_values => [ qw/ninkasi@ajk.name/ ],
    }
);

ok $sth->fetch();

my $judge_id = $result->{judge_id};
ok $judge_id;

is $result->{ address             }, '123 Fake Street'  ;
is $result->{ bjcp_id             }, 'Z9999'            ;
is $result->{ city                }, 'Springfield'      ;
is $result->{ competitions_judged }, 10                 ;
is $result->{ email               }, 'ninkasi@ajk.name' ;
is $result->{ first_name          }, 'Andrew'           ;
is $result->{ flight1             }, 1                  ;
is $result->{ flight3             }, 1                  ;
is $result->{ last_name           }, 'Korty'            ;
is $result->{ phone_day           }, '123-456-7890'     ;
is $result->{ phone_evening       }, '123-456-7890'     ;
is $result->{ rank                }, 50                 ;
is $result->{ state               }, '--'               ;
is $result->{ zip                 }, 12345              ;

ok !$result->{flight2};

my $constraint = Ninkasi::Constraint->new();
ok $constraint;
($sth, $result) = $constraint->bind_hash(
    {
        columns     => [ qw/category type/ ],
        where       => 'judge = ?',
        bind_values => [ $judge_id ],
    }
);

my %expected_constraint = (
     1 => 'whatever'   ,
     2 => 'prefer'     ,
     3 => 'whatever'   ,
     4 => 'whatever'   ,
     5 => 'whatever'   ,
     6 => 'whatever'   ,
     7 => 'whatever'   ,
     8 => 'entry'      ,
     9 => 'whatever'   ,
    10 => 'entry'      ,
    11 => 'whatever'   ,
    12 => 'whatever'   ,
    13 => 'whatever'   ,
    14 => 'whatever'   ,
    15 => 'entry'      ,
    16 => 'whatever'   ,
    17 => 'whatever'   ,
    18 => 'whatever'   ,
    19 => 'whatever'   ,
    20 => 'prefer not' ,
    21 => 'entry'      ,
    22 => 'whatever'   ,
    23 => 'whatever'   ,
    24 => 'prefer'     ,
);

my $rows_fetched = 0;
while ( $sth->fetch() ) {
    is $result->{type}, $expected_constraint{ $result->{category} };
    ++$rows_fetched;
}

is $rows_fetched, scalar keys %expected_constraint, 'number of constraints';
