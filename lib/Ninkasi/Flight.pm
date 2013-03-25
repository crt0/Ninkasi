package Ninkasi::Flight;

use strict;
use warnings;

use base 'Ninkasi::Table';

use Ninkasi::FlightCategory;
use Ninkasi::Template;
use Ninkasi::Volunteer;

__PACKAGE__->Table_Name('flight');
__PACKAGE__->Column_Names( [ qw/description pro number/ ] );
__PACKAGE__->Schema(<<'EOF');
CREATE TABLE flight (
    description        TEXT,
    pro                INTEGER DEFAULT 0,
    number             TEXT UNIQUE
)
EOF

sub fetch {
    my ($judge_id) = @_;

    # build an index of missing rows (we'll remove the flights we find)
    my $flight_table = __PACKAGE__->new();
    my $not_found
        = $flight_table->Database_Handle()
                       ->selectall_hashref( 'SELECT number FROM flight',
                                            'number' );

    # fetch flights of each constraint type
    my $where_clause = <<EOF;
volunteer.rowid = 'constraint'.volunteer
    AND 'constraint'.category = flight_category.category
    AND flight.rowid = flight_category.flight
    AND 'constraint'.volunteer = ?
EOF
    my ( $flight_handle, $flight ) = $flight_table->bind_hash( {
        bind_values => [ $judge_id, $Ninkasi::Constraint::NUMBER{entry} ],
        columns     => [ qw/ number MAX(type) pro_brewer pro / ],
        join        => [ qw/ Ninkasi::Constraint Ninkasi::FlightCategory
                             Ninkasi::Volunteer / ],
        where       => $where_clause,
        group_by    => 'volunteer.rowid, flight_category.flight, number, '
                       . 'pro_brewer, pro',
        having      => 'MAX(type) != ? OR volunteer.pro_brewer != flight.pro',
        order_by    => 'number',
    } );
    $flight_handle->bind_col( 2, \$flight->{type} );

    # intialize a hash to store the constraint lists (indexed by type name)
    my %constraint = ();

    # walk the rows, building constraint lists
    while ( $flight_handle->fetch() ) {

        # adjust for entries in the other division
        my $type = $flight->{type} == $Ninkasi::Constraint::NUMBER{entry}
                   && $flight->{pro_brewer} != $flight->{pro}
                 ? $Ninkasi::Constraint::NUMBER{whatever}
                 : $flight->{type}
                 ;

        # add this flight to the appropriate constraint list
        push @{ $constraint{ $Ninkasi::Constraint::NAME{ $type } } },
             $flight->{number};

        # we found a constraint for this flight, so delete it from %$not_found
        delete $not_found->{ $flight->{number} };
    }

    # add any missing rows to the 'whatever' list
    @{ $constraint{whatever} }
        = sort keys %$not_found, @{ $constraint{whatever} || [] };

    # return the hash of constraint lists
    return \%constraint;

}

sub update_flights {
    my ($argument) = @_;

    # get a database handle
    my $dbh = __PACKAGE__->Database_Handle();

    # keep track of flight names to ensure uniqueness
    my %names_seen = ();

    # disable autocommit to perform this operation as one transaction
    $dbh->begin_work();
    eval {
        # clear the tables
        $dbh->do('DELETE FROM flight');
        $dbh->do('DELETE FROM flight_category');

        # build table of input data
        my %input_table = ();
        my $permitted_column = __PACKAGE__->Column_Names_Hash();
        while ( my ( $name, $value ) = each %$argument ) {
            my ( $column, $row ) = split /_/, $name;
            next if !exists $permitted_column->{$column}
                    && $column ne 'category';
            $input_table{$row}{$column} = $value;
        }

        # prepare statement handle for flight table
        my @columns = keys %$permitted_column;
        my $column_list = join ', ', @columns;
        my $flight_handle = $dbh->prepare(<<EOF);
INSERT INTO flight ($column_list) VALUES (?, ?, ?)
EOF

        # prepare statement handle for flight-category mapping table
        my $flight_category_handle = $dbh->prepare(<<EOF);
INSERT INTO flight_category (category, flight) VALUES (?, ?)
EOF

        # update tables row by row
        while ( my ( $row_number, $flight ) = each %input_table ) {

            # sanity check flight name (still called "number" in database)
            next if !defined $flight->{number} || $flight->{number} eq '';

            # check for uniqueness of flight names
            if ( exists $names_seen{ $flight->{number} } ) {
                die {
                    message => 'Flight names must be unique.',
                    row     => $flight->{number},
                };
            }

            # else remember this one
            else {
                $names_seen{ $flight->{number} } = 1;
            }

            # default to homebrew
            $flight->{pro} ||= 0;

            # execute query
            $flight_handle->execute( @$flight{@columns} );

            # get flight rowid
            my $flight_id = $dbh->last_insert_id( (undef) x 4 );

            # parse categories and add to mapping table
            foreach my $category ( split /[, ]+/, $flight->{category} ) {
                $flight_category_handle->execute( $category, $flight_id );
            }

        }
    };

    # on error, rollback, re-enable autocommit, & propagate the error
    if ($@) {
        $dbh->rollback();
        return $@ if ref $@;
        die;
    }

    # on success, commit, & re-enable autocommit
    else {
        $dbh->commit();
    }

    return;
}

# fake flight data from CGI query
sub fake_flight {
    my ($argument) = @_;

    my $iteration = 1;

    return sub {
        my $flight_number = $argument->{"number_$iteration"};
        return if !defined $flight_number || $flight_number eq '';

        my $names = __PACKAGE__->Column_Names();

        my %row = map { $_ => scalar $argument->{"${_}_$iteration"} }
                      @{ __PACKAGE__->Column_Names() }, 'category';
        ++$iteration;

        return \%row;
    };
}

sub get_assigned_judges {
    my ($flight) = @_;

    # get list of judge names
    my $judge_table = Ninkasi::Volunteer->new();
    my $sth = $judge_table->prepare( {
        columns     => [ qw/first_name last_name/ ],
        join        => 'Ninkasi::Assignment',
        order_by    => 'rank DESC, competitions_judged DESC',
        where       => 'volunteer.rowid = assignment.volunteer'
            . ' AND assignment.flight = ?'
        } );
    $sth->execute( $flight->{number} );

    # append first and last names
    return [ map { join q{ }, @$_ } @{ $sth->fetchall_arrayref() } ];
}

sub transform {
    my ( $class, $argument ) = @_;

    # process input
    if ( $argument->{save} ) {
        my $error = update_flights $argument;

        return {
            error        => $error,
            fetch_flight => fake_flight($argument),
        } if $error;
    }

    # select whole table & order by category, then number
    my $column_list = join ', ', @{ $class->Column_Names() };
    my ( $handle, $result ) = $class->new()->bind_hash( {
        columns  => [ 'group_concat("category", " ")',
                      @{ $class->Column_Names() } ],
        join     => 'Ninkasi::FlightCategory',
        order_by => 'number',
        where    => 'flight.rowid = flight_category.flight',
        group_by => $column_list,
    } );
    $handle->bind_col( 1, \$result->{category} );

    return {
        fetch_flight => sub {
            if ( $handle->fetch() ) {
                $result->{judges} = get_assigned_judges $result;
                return $result;
            }
            else {
                return;
            }
        },
    };
}

1;

__END__

=head1 NAME

Ninkasi::Flight - table of flight names and descriptions

=head1 SYNOPSIS

  use Ninkasi::Flight;

  # transform user interface input into template input (really only
  # called by Ninkasi(3))
  $transform_results = Ninkasi::Flight->transform( {
      \%options,
      -positional => \%positional_parameters,
  } );
  Ninkasi::Template->new()->process( flight => $transform_results);

  # fetch flights a given volunteer can judge, organized by constraint
  $constraint_hashref = Ninkasi::Flight::fetch $volunteer->{rowid};
  print "Flights $volunteer->{last_name} prefers to judge: ",
    join( ', ', $constraint_hashref->{prefer} ), "\n";

  # get all judges assigned to a given flight
  $judges = Ninkasi::Flight::get_assigned_judges $flight;
  print "Judges assigned to $flight->{description}: ",
    join( ', ', @$judges ), "\n";

=head1 DESCRIPTION

Ninkasi::Flight provides an interface to a database table of
a competition's flight names and descriptions.

=head1 SUBROUTINES/METHODS

Ninkasi::Flight defines a C<transform()> method to be called by
L<Ninkasi(3)>; see the latter for documentation on this method.

This module is a subclass of L<Ninkasi::Table(3)>.  The following
subroutines/methods are defined in addition to those inherited:

=over 4

=item $constraint_hashref = fetch $volunteer_id

Fetch all flights a volunteer is eligible to judge, organized by
constraint type.  C<$constraint_hashref> maps each constraint type
(see L<Ninkasi::Constraint(3)>) to a reference to an array of flight
numbers.

=item $judges_arrayref = get_assigned_judges $flight

Fetch all judges assigned to C<$flight> (a L<Ninkasi::Flight(3)>
object) and return them as a reference to an array of strings of the
form "FIRSTNAME LASTNAME".

=back

=head1 ATTRIBUTES

The following attributes are represented as columns in the database
table.

=over 4

=item description (TEXT)

Description of the flight.

=item pro (INTEGER)

Which division the flight is in -- professional (1) or homebrew (0).

=item number (TEXT)

Name of the flight (will be renamed to C<name> in the future).

=back

=head1 DIAGNOSTICS

If this module encounters an error while rendering a template,
C<Ninkasi::Template-E<gt>error()> is called to generate a warning message
that is printed on C<STDERR>.  If an error is encountered while
updating a flight, the database is rolled back.

=head1 CONFIGURATION

No L<Ninkasi::Config(3)> variables are used by this module.

=head1 BUGS AND LIMITATIONS

This class doesn't use L<Ninkasi::Judge(3)> properly as a subclass of
L<Ninkasi::Volunteer(3)> but instead reaches into the latter.

Please report problems to Andrew Korty <andrew@korty.name>.  Patches
are welcome.

=head1 AUTHOR

Andrew Korty <andrew@korty.name>

=head1 LICENSE AND COPYRIGHT

This software is in the public domain.

=head1 SEE ALSO

L<Ninkasi(3)>, L<Ninkasi::Constraint(3)>, L<Ninkasi::Judge(3)>,
L<Ninkasi::Table(3)>, L<Ninkasi::Volunteer(3)>
