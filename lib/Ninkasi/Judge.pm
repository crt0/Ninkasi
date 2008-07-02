package Ninkasi::Judge;

use strict;
use warnings;

use base 'Ninkasi::Table';

__PACKAGE__->Table_Name('judge');
__PACKAGE__->Column_Names(qw/judge_id first_name last_name address city
                             state zip phone_evening phone_day email rank
                             bjcp_id flight1 flight2 flight3
                             competitions_judged pro_brewer when_created/);
__PACKAGE__->Create_Sql(<<'EOF');
CREATE TABLE judge (
    judge_id            TEXT PRIMARY KEY,
    first_name          TEXT,
    last_name           TEXT,
    address             TEXT,
    city                TEXT,
    state               TEXT,
    zip                 TEXT,
    phone_evening       TEXT,
    phone_day           TEXT,
    email               TEXT,
    rank                INTEGER,
    bjcp_id             TEXT,
    flight1             INTEGER,
    flight2             INTEGER,
    flight3             INTEGER,
    competitions_judged INTEGER,
    pro_brewer          INTEGER,
    when_created        INTEGER
)
EOF

our @RANKS = (
    {
        description => 'Novice -- little or no judging experience',
        name        => 'Novice',
        number      => 10,
    },
    {
        description => 'Experienced but not in the BJCP',
        name        => 'Experienced',
        number      => 20,
    },
    {
        description => 'BCJP Apprentice',
        name        => 'Apprentice',
        number      => 30,
    },
    {
        description => 'BJCP Recognized',
        name        => 'Recognized',
        number      => 40,
    },
    {
        description => 'BJCP Certified',
        name        => 'Certified',
        number      => 50,
    },
    {
        description => 'BJCP National',
        name        => 'National',
        number      => 60,
    },
    {
        description => 'BJCP Master',
        name        => 'Master',
        number      => 70,
    },
    {
        description => 'BJCP Grand Master',
        name        => 'Grand Master',
        number      => 80,
    },
);

our (%NAME, %NUMBER);
foreach my $rank (@RANKS) {
    $NAME  { $rank->{number} } = $rank->{name  };
    $NUMBER{ $rank->{name  } } = $rank->{number};
}

1;
