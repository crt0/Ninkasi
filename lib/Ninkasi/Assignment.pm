package Ninkasi::Assignment;

use strict;
use warnings;

use base 'Ninkasi::Table';

use IPC::Open2 ();
use Ninkasi::Constraint;
use Ninkasi::Flight;
use Ninkasi::Judge;
use Ninkasi::Volunteer;
use Readonly;

__PACKAGE__->Table_Name('assignment');
__PACKAGE__->Column_Names( [ qw/flight session volunteer/ ] );
__PACKAGE__->Schema(<<'EOF');
CREATE TABLE assignment (
    flight    TEXT,
    session   INTEGER,
    volunteer INTEGER
)
EOF

Readonly our $REPORT_LINES_PER_PAGE => 39;

# return a list of assignments for a specified judge
sub fetch {
    my ($judge_id) = @_;

    # fetch assignments for specified judge
    my $assignment = Ninkasi::Assignment->new();
    my ($sth, $result) = $assignment->bind_hash( {
        bind_values => [$judge_id],
        columns     => [qw/flight session/],
        where       => 'volunteer = ?',
    } );

    # walk the rows, building a list ordered by flight
    my @assignment_list = ('N/A') x 4;
    while ( $sth->fetch() ) {
        # treat category value 0 as unassigned
        $assignment_list[ $result->{session} ]
            = $result->{flight} ? $result->{flight} : '';
    }

    return \@assignment_list;
}

sub select_assigned_judges {
    my ($flight) = @_;

    my @columns = qw/volunteer.rowid first_name last_name rank
                     competitions_judged pro_brewer role/;
    my $column_list = join ', ', @columns;

    my $judge = Ninkasi::Volunteer->new();
    my $where_clause = <<EOF;
volunteer.rowid = 'constraint'.volunteer
    AND 'constraint'.category = flight_category.category
    AND flight.rowid = flight_category.flight
    AND flight.number = ?
    AND volunteer.rowid IN (SELECT volunteer FROM assignment WHERE flight = ?)
EOF
    my ($sth, $result) = $judge->bind_hash( {
        bind_values => [ ( $flight->{number} ) x 2 ],
        columns     => [ 'MAX(type)', @columns ],
        join        => [ qw/Ninkasi::Constraint Ninkasi::Flight
                            Ninkasi::FlightCategory/ ],
        where       => $where_clause,
        group_by    => "$column_list, flight_category.flight",
        order_by    => 'rank DESC, competitions_judged DESC, type DESC',
    } );
    $sth->bind_col( 1, \$result->{type } );
    $sth->bind_col( 2, \$result->{rowid} );

    return sub {
        return if !$sth->fetch();

        # display entries in other divisions as "whatever"
        if ( $result->{type} == $Ninkasi::Constraint::NUMBER{entry} ) {
            $result->{type} = $Ninkasi::Constraint::NUMBER{whatever};
        }

        return {
            %$result,
            fetch_assignments => sub { fetch $result->{rowid} },
        };
    };
}

sub select_unassigned_judges {
    my ($flight) = @_;

    my @columns = qw/volunteer.rowid first_name last_name rank
                     competitions_judged pro_brewer role/;
    my $column_list = join ', ', @columns;

    my $where_clause = <<EOF;
volunteer.rowid = 'constraint'.volunteer
    AND flight.rowid = flight_category.flight
    AND 'constraint'.category = flight_category.category
    AND flight.number = ?
    AND volunteer.rowid IN (SELECT volunteer FROM assignment WHERE flight = 0)
    AND volunteer.rowid NOT IN (SELECT volunteer FROM assignment WHERE flight = ?)
    AND volunteer.role = 'judge'
EOF
    my $having_clause = <<EOF;
MAX(type) != $Ninkasi::Constraint::NUMBER{entry}
    OR volunteer.pro_brewer != flight.pro
EOF
    my $flight_table = Ninkasi::Flight->new();
    my ( $handle, $result ) = $flight_table->bind_hash( {
        bind_values => [ ( $flight->{number} ) x 2 ],
        columns     => [ @columns, 'MAX(type)' ],
        join        => [ qw/Ninkasi::Constraint Ninkasi::FlightCategory
                            Ninkasi::Volunteer/ ],
        where       => $where_clause,
        group_by    => "$column_list, flight_category.flight",
        having      => $having_clause,
        order_by    => 'MAX(type), rank DESC, competitions_judged DESC',
    } );
    $handle->bind_col( 1, \$result->{rowid} );
    $handle->bind_col( $#columns + 2, \$result->{type} );

    return sub {
        return if !$handle->fetch();

        # display entries in other divisions as "whatever"
        if ( $result->{type} == $Ninkasi::Constraint::NUMBER{entry} ) {
            $result->{type} = $Ninkasi::Constraint::NUMBER{whatever};
        }

        return {
            %$result,
            fetch_assignments => sub { fetch $result->{rowid} },
        };
    };
}

sub serialize {
    my ($data) = @_;
    return join '_', map { join '-', $_, $data->{$_} } keys %$data;
}

sub deserialize {
    my ($string) = @_;

    my %data = ();
    foreach my $pair (split /_/, $string) {
        my ($name, $value) = split /-/, $pair;
        $data{$name} = $value;
    }

    return \%data;
}

sub update_assignment {
    my ($assignments, $flight_number) = @_;

    my $dbh = Ninkasi::Assignment->Database_Handle();
    my @columns = qw/volunteer session/;
    foreach my $assignment (@$assignments) {
        my $constraint = deserialize $assignment;
        my $sql = <<EOF;
UPDATE assignment SET flight = ? WHERE volunteer = ? AND session = ?
EOF
        $dbh->do($sql, {}, $flight_number, @$constraint{@columns});
    }
}

sub groff_to_pdf {
    my ($groff, @options) = @_;

    $ENV{PATH} = Ninkasi::Config->new()->path();
    my ( $groff_pid, $groff_reader, $groff_writer );
    $groff_pid = IPC::Open2::open2 $groff_reader, $groff_writer,
                                   qw/groff -Tps/, @options;

    print $groff_writer $groff;
    close $groff_writer;
    local $/;
    my $postscript = <$groff_reader>;
    close $groff_reader;
    waitpid $groff_pid, 0;

    my ( $ps2pdf_pid, $ps2pdf_reader, $ps2pdf_writer );
    $ps2pdf_pid = IPC::Open2::open2 $ps2pdf_reader, $ps2pdf_writer,
                                    qw/ps2pdf - -/;
    print $ps2pdf_writer $postscript;
    close $ps2pdf_writer;
    my $pdf = <$ps2pdf_reader>;
    close $ps2pdf_reader;
    waitpid $ps2pdf_pid, 0;

    return $pdf;
}

sub print_roster {
    my ($role) = @_;

    # select whole judge table & order by last name
    my $volunteer_table = Ninkasi::Volunteer->new();
    my ( $volunteer_handle, $volunteer ) = $volunteer_table->bind_hash( {
        bind_values => [$role],
        columns     => [ qw/rowid first_name last_name/ ],
        order_by    => 'last_name',
        where       => 'role = ?',
    } );

    my $assignment_table = Ninkasi::Assignment->new();
    my $capitalized_role = ucfirst $role;
    my @groff = ();
    for (;;) {

        my @rows = ();
        my $finished = 0;
        for (;;) {

            if ( !$volunteer_handle->fetch() ) {
                $finished = 1;
                last;
            }

            # find out for which sessions volunteer is available
            my @assignments = ('N/A') x 4;
            my ( $assignment_handle, $result )
                = $assignment_table->bind_hash( {
                bind_values => [ $volunteer->{rowid} ],
                columns     => ['session'],
                where       => 'volunteer = ? AND flight = 0',
            } );
            while ( $assignment_handle->fetch() ) {
                delete $assignments[ $result->{session} ];
            }

            my @columns = qw/flight session description number pro/;
            ( $assignment_handle, $result )
                = $assignment_table->bind_hash( {
                    bind_values => [ $volunteer->{rowid} ],
                    columns     => \@columns,
                    join        => 'Ninkasi::Flight',
                    where       => 'assignment.flight = flight.number' .
                                   ' AND volunteer = ?',
                } );
            while ( $assignment_handle->fetch() ) {
                my $division = $result->{pro} ? 'pro' : 'hb';
                $assignments[ $result->{session} ] =
                    "$result->{number}: $result->{description} ($division)";
            }
            push @rows,
                join ';', "$volunteer->{last_name}, $volunteer->{first_name}",
                          map { defined $_ ? $_ : '' } @assignments[1..3];

            last if @rows >= $REPORT_LINES_PER_PAGE;
        }

        # draw a horizonal line every three rows for legibility
        my $rows = '';
        my @triplets = ();
        while ( my @three = splice @rows, 0, 3 ) {
            push @triplets, join "\n", @three;
        }
        $rows = join "\n_\n", @triplets;
        push @groff, <<EOF;
.fam H
.ps 8
.sp 2
.TS
tab(;);
lb lb lb lb
l  l  l  l  .
$capitalized_role;Friday PM;Saturday AM; Saturday PM
_
$rows
.TE
EOF

        last if $finished;
    }

    return groff_to_pdf join("\n.bp\n", @groff), qw/-t -P-l/;
}

sub print_table_card {
    my ($flight) = @_;

    my $division = $flight->{pro} ? 'Professional' : 'Homebrew';

    my $judge_table = Ninkasi::Volunteer->new();
    my ( $sth, $result ) = $judge_table->bind_hash( {
        bind_values => [ $flight->{number} ],
        columns     => [ qw/first_name last_name session/ ],
        join        => 'Ninkasi::Assignment',
        order_by    => 'rank DESC, competitions_judged DESC',
        where       => 'volunteer.rowid = assignment.volunteer'
                       . ' AND assignment.flight = ?'
    } );

    $sth->fetch();
    my $head_judge = join ' ', @$result{ qw/first_name last_name/ };
    my $session = $result->{session} == 1 ? 'Friday PM'
                : $result->{session} == 2 ? 'Saturday AM'
                :                           'Saturday PM'
                ;

    my @other_judges_list = ();
    while ( $sth->fetch() ) {
        push @other_judges_list, join ' ', @$result{ qw/first_name last_name/ };
    }
    my $other_judges = join "\n.brp\n", @other_judges_list;

    return groff_to_pdf <<EOF;
.fam H
.nh
.ad c
.ps 32
.vs 38
.sp
$session
.sp
.ps 96
.vs 115
Table $flight->{number}
.ps 48
.vs 58
.sp
$flight->{description}
.brp
$division Division
.sp
.ps 32
.vs 38
.ft I
$head_judge
.ft
.brp
$other_judges
EOF
}

sub flatten {
    my ($data) = @_;

    return if !defined $data;
    return ref $data ? @$data : $data;
}

sub transform {
    my ( $self, $argument ) = @_;

    my $flight_number = $argument->{-positional}[0];
    my $format        = $argument->{format     }   ;
    my @assign        = flatten $argument->{assign  };
    my @unassign      = flatten $argument->{unassign};

    # parse path_info to get flight number and then flight info from db
    my $flight_table = Ninkasi::Flight->new();
    my ($sth, $flight) = $flight_table->bind_hash( {
        bind_values => [$flight_number],
        columns     => [qw/description pro number/],
        limit       => 1,
        where       => 'number = ?',
    } );

    die {
        add_flights => 1,
        message     => "Flight $flight_number not found.",
        status      => 404,
        title       => "Flight $flight_number Not Found",
    } if !$sth->fetch();

    $sth->finish();

    # process table card
    return { content => print_table_card $flight } if $format eq 'print';

    # process input
    if (@assign) {
        update_assignment \@assign  , $flight_number;
    }
    if (@unassign) {
        update_assignment \@unassign, 0;
    }

    # process the template, passing it a function to fetch judge data
    return {
        assigned_judges_func   => sub { select_assigned_judges $flight },
        constraint_name        => \%Ninkasi::Constraint::NAME,
        flight                 => $flight,
        rank_name              => \%Ninkasi::Judge::NAME,
        type                   => $format,
        unassigned_judges_func => sub { select_unassigned_judges $flight },
    };
}

1;
__END__

=head1 NAME

Ninkasi::Assignment - mapping of judges to their assigned flights and sessions

=head1 SYNOPSIS

    use Ninkasi::Assignment;

    # render a web page displaying all assignments
    Ninkasi::Assignment->render_page( Ninkasi::CGI->new() );

    # look up a judge in the assignment table; display that judge's assignments
    my $assignment_table = Ninkasi::Assignment->new();
    my ( $assignment_handle, $assignment ) = $assignment_table->bind_hash( {
        bind_values => [ $judge_id ],
        columns     => [ qw/flight session/ ],
        order_by    => 'session',
        where       => 'volunteer = ?',
    } );
    print "Judge: $judge_id\n";
    while ( $assignment_handle->fetch() ) {
        print <<EOF;
  Session $assignment->{session}: Flight $assignment->{flight}
EOF
    }

=head1 DESCRIPTION

Ninkasi::Assignment provides an interface to a database table of
assignments of judges (see L<Ninkasi::Volunteer>) to flights (see
L<Ninkasi::Flight>) for each session (see L<Ninkasi::Session>).

=head1 METHODS

=over 4

=item Ninkasi::Assignment->render_page($cgi_object)

Render a web page using the F<assignment.html> template (see
L<Ninkasi::Template>) to display the assignments for all judges in a
form that allows competition organizers to edit these assignments.
Uses the Ninkasi::CGI(3) object C<$cgi_object>.

=item $hash_ref = select_assigned_judges $flight_object

Given a Ninkasi::Flight object C<$flight_object>, return an iterator
that fetches data corresponding to each successive assigned judge,
returned as a reference to a hash containing the following entries:

 Attribute            Class
 =========            =====

 rowid                Volunteer attribute
 first_name                 "
 last_name                  "
 rank                       "
 competitions_judged        "
 pro_brewer                 "
 type                 Constraint attribute
 fetch_assignments    reference to subroutine that returns list of
                      flight numbers (or the string 'N/A' if not
                      assigned) to which this judge is assigned, in
                      session order

=item $hash_ref = select_unassigned_judges $flight_object

Given a Ninkasi::Flight object C<$flight_object>, return an iterator
that fetches data corresponding to each successive judge not assigned
but available to judge that flight, returned as a reference to a hash
containing the following entries:

 Attribute            Class
 =========            =====

 rowid                Volunteer attribute
 first_name                 "
 last_name                  "
 rank                       "
 competitions_judged        "
 pro_brewer                 "
 constraint           Constraint attribute
 type                       "
 fetch_assignments    reference to subroutine that returns list of
                      flight numbers (or the string 'N/A' if not
                      assigned) to which this judge is assigned, in
                      session order

=item $string = serialize $hash_ref

Serialize hash referenced by I<$hash_ref> into a string of the form
C<key1-value1_key2-value2...>.  Used in passing assignment data via
HTTP query parameters.

=item $hash_ref = deserialize $string

Reverse of I<serialize>, above.

=item update_assignment $assignments, $flight_number

Update stored list of assignments for I<$flight_number> according to
the serialized list of assignments in I<$assignments> (see
L</serialize>).

=item print_roster

Produce a PDF of the entire judge roster on C<STDOUT>.

=item print_table_card $flight

Produce a PDF of the table card for $flight on C<STDOUT>.

=back

=head1 DIAGNOSTICS

The I<print_*> routines produce warnings on C<STDERR> when problems
are encountered running groff(1) to generate the PDF output.

If this module encounters an error while rendering a template,
I<Ninkasi::Template->error()> is called to generate a warning message
that is printed on C<STDERR>.

=head1 CONFIGURATION

No Ninkasi::Config(3) variables are used by this module.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.  Please report problems to
Andrew Korty <ajk@iu.edu>.  Patches are welcome.

=head1 AUTHOR

Andrew Korty <ajk@iu.edu>

=head1 LICENSE AND COPYRIGHT

This software is in the public domain.

=head1 SEE ALSO

groff(1), Ninkasi::CGI(3), Ninkasi::Constraint(3), Ninkasi::Flight(3),
Ninkasi::Volunteer(3), Ninkasi::Session(3), Ninkasi::Template(3)
