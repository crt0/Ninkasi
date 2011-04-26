package Ninkasi::Volunteer;

use strict;
use warnings;

use base 'Ninkasi::Table';

use Ninkasi::Assignment;
use Ninkasi::CSV;
use Ninkasi::Category;
use Ninkasi::Constraint;
use Ninkasi::Template;

__PACKAGE__->Table_Name('volunteer');
__PACKAGE__->Column_Names( [ qw/first_name last_name address city state zip
                                phone_evening phone_day email rank bjcp_id
                                competitions_judged pro_brewer
                                when_created role/ ] );
__PACKAGE__->Schema(<<'EOF');
CREATE TABLE volunteer (
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
    when_created        INTEGER,
    role                TEXT
)
EOF

sub role { lcfirst ( ( split '::', ref $_[0] || $_[0] )[-1] ) }

sub add {
    my ( $self, $column ) = @_;

    $column->{role} = $self->role();

    return $self->SUPER::add($column);
}

# display big table of all volunteers
sub get_all {
    my ( $class, $argument ) = @_;

    # select whole table & order by last name
    my $volunteer_table = $class->new();
    my $quoted_role
        = $volunteer_table->Database_Handle->quote( $class->role() );
    my ( $volunteer_handle, $volunteer_row ) = $volunteer_table->bind_hash( {
        columns  => [ qw/rowid first_name last_name rank competitions_judged
                         pro_brewer/ ],
        order_by => 'last_name',
        where    => "role = $quoted_role"
    } );

    # return callback to fetch volunteer data and some helper functions
    return {
        argument => $argument,
        fetch_volunteer => sub {
            $volunteer_handle->fetch() && {
                %$volunteer_row,
                fetch_assignments => sub {
                    return Ninkasi::Assignment::fetch $volunteer_row->{rowid};
                },
                fetch_flights => sub {
                    return Ninkasi::Flight::fetch $volunteer_row->{rowid};
                },
            };
        },
        title => "Registered ${quoted_role}s",
    };
}

sub transform {
    my ( $class, $argument ) = @_;

    my $volunteer_id = $argument->{-positional}[0];

    # print roster if requested
    return { content => &Ninkasi::Assignment::print_roster }
           if $argument->{format} eq 'print';

    # show all volunteers if no id is specified
    if (!$volunteer_id) {
        return $class->get_all($argument);
    }

    # specialize where clause if a role is specified
    my $volunteer_table = $class->new();
    my $where_clause = 'rowid = ? AND role = '
                       . $volunteer_table->Database_Handle
                                         ->quote( $class->role() );

    # fetch the row for this volunteer from the database
    my ( $volunteer_handle, $volunteer_row ) = $volunteer_table->bind_hash( {
        bind_values => [$volunteer_id],
        columns     => [ qw/rowid first_name last_name address city state zip
                            phone_evening phone_day email rank bjcp_id
                            competitions_judged pro_brewer when_created/ ],
        limit       => 1,
        where       => $where_clause,
    } );
    $volunteer_handle->fetch();
    $volunteer_handle->finish();

    return {
        rank_name     => \%Ninkasi::Judge::NAME,
        volunteer_row => $volunteer_row,
    };
}

1;
