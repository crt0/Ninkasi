package Ninkasi::Roster;

use strict;
use warnings;

use base 'Ninkasi::Table';

use Ninkasi::Template;
use Ninkasi::Volunteer;

sub fetch_assignments {
    my ($judge_id) = @_;

    # fetch assignments for specified judge
    my $assignment = Ninkasi::Assignment->new();
    my ( $sth, $result ) = $assignment->bind_hash( {
        bind_values => [$judge_id],
        columns     => [qw/flight session number description pro/],
        join        => 'Ninkasi::Flight',
        where       => 'assignment.flight = flight.number AND volunteer = ?',
    } );

    my @assignments = ();
    while ( $sth->fetch() ) {
        $assignments[ $result->{session} ] = $result->{flight} && $result;
    }

    return \@assignments;
}

sub transform {
    my ( $class, $argument ) = @_;

    # check if page is enabled
    my $credential = Ninkasi::Config->new()->get('roster');
    if ( !defined $credential ) {
        die {
            message => <<EOF,
Organizers are still working on the judge roster.  Please try back
later.
EOF
            status  => 404,
            title   => 'Brewers&#8217; Cup Roster Unavailable',
        };
    }

    # you have to have the random URL to get to this page
    if ( $credential ne $argument->{-positional}[0] ) {
        die {
            message => "You don't have access to this page",
            status  => 403,
            title   => 'Brewers&#8217; Cup Access Denied',
        };
    }

    # fetch the row for this volunteer from the database
    my $volunteer_table = Ninkasi::Volunteer->new();
    my ( $volunteer_handle, $volunteer_row ) = $volunteer_table->bind_hash( {
        columns     => [ qw/rowid first_name last_name/ ],
        order_by    => 'last_name',
        where       => "role = 'judge'",
    } );

    return {
        fetch_volunteer => sub {
            $volunteer_handle->fetch() && {
                %$volunteer_row,
                fetch_assignments => sub {
                    return fetch_assignments $volunteer_row->{rowid};
                },
            };
        },
    };
}

1;
