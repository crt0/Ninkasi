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
__END__

=head1 NAME

Ninkasi::Roster - provide a semi-public view of judge assignments

=head1 SYNOPSIS

  use Ninkasi::Roster;
  
  my $flight = Ninkasi::Roster->fetch_flight($flight_name);
  print "$flight->{number}: $flight->{description} (",
        ( $flight->{pro} ? 'pro' : 'hb' ),
        ")\n";

=head1 DESCRIPTION

Ninkasi::Roster provides a semi-public view of assigned judges.
Competition organizers can provide a hard-to-guess URL to judges so
they can prepare for the event without tipping off entrants which
judges will be judging their entries, which could result in
impropriety.  This view is enabled by setting the configuration
variable C<roster> to a hard-to-guess value.  See L<"EXAMPLES"> below.

=head1 SUBROUTINES/METHODS

Ninkasi::Roster defines a C<transform()> method to be called by
L<Ninkasi(3)>; see the latter for documentation on this method.

=head1 DIAGNOSTICS

If this module encounters an error while rendering a template,
C<Ninkasi::Template-E<gt>error()> is called to generate a warning message
that is printed on C<STDERR>.

=head1 CONFIGURATION

The following L<Ninkasi::Config(3)> variables are used by this module:

=over 4

=item roster

when defined, enable the semi-public roster view, the value being used
to derive the URL to the roster view

=back

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.  Please report problems to
Andrew Korty <andrew@korty.name>.  Patches are welcome.

=head1 AUTHOR

Andrew Korty <andrew@korty.name>

=head1 LICENSE AND COPYRIGHT

This software is in the public domain.

=head1 EXAMPLES

One way to provide a unique, hard-to-guess URL to the roster view is
to set the C<roster> configuration variable to a UUID, such as
C<11FAB655-4144-4A22-B69A-BCFFFA2B9DA0>.  Setting in the
C<ninkasi.conf> file

  roster = 11FAB655-4144-4A22-B69A-BCFFFA2B9DA0

would activate the URL

  http://<hostname>/roster/11FAB655-4144-4A22-B69A-BCFFFA2B9DA0

This URL could then be shared with judges (but not entrants or the
general public), who could access it to view what categories and
flights they've been assigned.  If competition organizers later adjust
the assignments, this view will update immediately and automatically.

=head1 SEE ALSO

L<Ninkasi(3)>, L<Ninkasi::Config(3)>, L<Ninkasi::Template(3)>
