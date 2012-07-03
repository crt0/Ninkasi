package Ninkasi::Roster;

use strict;
use warnings;

use base 'Ninkasi::Table';

use Ninkasi::Template;
use Ninkasi::Volunteer;

sub fetch_flight {
    my ($flight_number) = @_;

    my $flight = Ninkasi::Flight->new();
    my ( $description, $number, $pro ) = $flight->get_one_row( {
        bind_values => [$flight_number],
        columns     => [qw/description number pro/],
        where       => 'number = ?',
    } );

    return {
        description => $description,
        number      => $number,
        pro         => $pro,
    };
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
                    return Ninkasi::Assignment::fetch $volunteer_row->{rowid};
                },
                fetch_flight => \&fetch_flight,
            };
        },
    };
}

1;
