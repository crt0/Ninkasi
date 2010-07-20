package Ninkasi::Judge;

use strict;
use warnings;

use base 'Ninkasi::Table';

use Ninkasi::Assignment;
use Ninkasi::CSV;
use Ninkasi::Category;
use Ninkasi::Constraint;
use Ninkasi::Template;

__PACKAGE__->Table_Name('judge');
__PACKAGE__->Column_Names(qw/first_name last_name address city state zip
                             phone_evening phone_day email rank bjcp_id
                             competitions_judged pro_brewer when_created/);
__PACKAGE__->Schema(<<'EOF');
CREATE TABLE judge (
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
    competitions_judged INTEGER,
    pro_brewer          INTEGER DEFAULT 0,
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

our ( %NAME, %NUMBER );
foreach my $rank (@RANKS) {
    $NAME  { $rank->{number} } = $rank->{name  };
    $NUMBER{ $rank->{name  } } = $rank->{number};
}

# display big table of all judges
sub get_all_judges {
    my ($argument) = @_;

    # select whole table & order by last name
    my ( $judge_handle, $judge_row ) = __PACKAGE__->new()->bind_hash( {
        columns  => [ qw/rowid first_name last_name rank competitions_judged
                         pro_brewer/ ],
        order_by => 'last_name',
    } );

    # return callback to fetch judge data and some helper functions
    return {
        argument              => $argument,
        fetch_judge           => sub {
            return $judge_handle->fetch() && {
                %$judge_row,
                fetch_assignments
                    => sub { Ninkasi::Assignment::fetch $judge_row->{rowid} },
                fetch_flights
                    => sub { Ninkasi::Flight::fetch $judge_row->{rowid} },
            };
        },
        title                 => 'Registered Judges',
    };
}

sub transform {
    my ( $class, $argument ) = @_;

    my $judge_id = $argument->{-nonoption}[0];

    # show all judges if no id is specified
    if (!$judge_id) {
        return get_all_judges $argument;
    }

    # fetch the row for this judge from the database
    my ( $judge_handle, $judge_row ) = $class->new()->bind_hash( {
        bind_values => [$judge_id],
        columns     => [ qw/rowid first_name last_name address city state zip
                            phone_evening phone_day email rank bjcp_id
                            competitions_judged pro_brewer when_created/ ],
        limit       => 1,
        where       => 'rowid = ?',
    } );
    $judge_handle->fetch();
    $judge_handle->finish();

    return {
        judge     => $judge_row,
        rank_name => \%Ninkasi::Judge::NAME,
        title     => join( ' ', @$judge_row{qw/first_name last_name/} ),
    };
}

1;
