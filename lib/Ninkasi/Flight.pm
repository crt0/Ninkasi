package Ninkasi::Flight;

use strict;
use warnings;

use base 'Ninkasi::Table';

use Ninkasi::FlightCategory;
use Ninkasi::Template;

__PACKAGE__->Table_Name('flight');
__PACKAGE__->Column_Names(qw/description pro number/);
__PACKAGE__->Schema(<<'EOF');
CREATE TABLE flight (
    description        INTEGER,
    pro                INTEGER DEFAULT 0,
    number             TEXT UNIQUE
)
EOF

sub fetch {
    my ($judge_id) = @_;

    # build an index of missing rows (we'll remove the flights we find)
    my $flight_table = Ninkasi::Flight->new();
    my $not_found
        = $flight_table->Database_Handle()
                       ->selectall_hashref( 'SELECT number FROM flight',
                                            'number' );

    # fetch flights of each constraint type
    my $where_clause = <<EOF;
judge.rowid = 'constraint'.judge
    AND 'constraint'.category = flight_category.category
    AND flight.rowid = flight_category.flight
    AND 'constraint'.judge = ?
EOF
    my ( $flight_handle, $flight ) = $flight_table->bind_hash( {
        bind_values => [ $judge_id, $Ninkasi::Constraint::NUMBER{entry} ],
        columns     => [ qw/ number MAX(type) pro_brewer pro / ],
        join        => [ qw/ Ninkasi::Constraint Ninkasi::FlightCategory
                             Ninkasi::Judge / ],
        where       => $where_clause,
        group_by    => 'judge.rowid, flight_category.flight',
        having      => 'MAX(type) != ? OR judge.pro_brewer != flight.pro',
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
    my ($cgi_object) = @_;

    # get a database handle
    my $dbh = __PACKAGE__->Database_Handle();

    # disable autocommit to perform this operation as one transaction
    $dbh->begin_work();
    eval {
    # clear the tables
        $dbh->do('DELETE FROM flight');
        $dbh->do('DELETE FROM flight_category');

        # build table of input data
        my %input_table = ();
        my $permitted_column = __PACKAGE__->_Column_Names();
        foreach my $name ( $cgi_object->param() ) {
            my ( $column, $row ) = split /_/, $name;
            next if !exists $permitted_column->{$column} && $column ne 'category';
            $input_table{$row}{$column} = $cgi_object->param($name);
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

            # sanity check row number
            next if !defined $flight->{number} || $flight->{number} eq '';

            # default to homebrew
            $flight->{pro} ||= 0;

            # update flight table and trap error on flight number clash
            eval { $flight_handle->execute(@$flight{@columns}) };
            if ($@) {
                $dbh->rollback();
                $dbh->{AutoCommit} = 1;
                my $message = $@ =~ /column number is not unique/
                    ? 'Flight names must be unique.'
                        : $@
                            ;
                return { row => $flight->{number}, message => $message };
            }

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
    my ($cgi_object) = @_;

    my $iteration = 1;

    return sub {
        my $flight_number = $cgi_object->param("number_$iteration");
        return if !defined $flight_number || $flight_number eq '';

        my $hashref = __PACKAGE__->_Column_Names();

        my %row = map { $_ => scalar $cgi_object->param("${_}_$iteration") }
                      keys %{ __PACKAGE__->_Column_Names() };
        ++$iteration;

        return \%row;
    };
}

sub render_page {
    my ($self, $cgi_object) = @_;

    # format parameter determines content type
    my $format = $cgi_object->param('format') || 'html';

    # create template object for output
    my $template_object = Ninkasi::Template->new();

    # transmit HTTP header
    $cgi_object->transmit_header();

    # process input
    if ( $cgi_object->param('save') ) {
        my $error = update_flights $cgi_object;

        if ($error) {
            $template_object->process( 'flight.tt', {
                error        => $error,
                fetch_flight => fake_flight($cgi_object),
                type         => $format,
            } ) or warn $template_object->error();

            return;
        }
    }

    # select whole table & order by category, then number
    my $flight = Ninkasi::Flight->new();
    my ($sth, $result) = $flight->bind_hash( {
        columns  => [ # 'group_concat("category", " ")',
                      keys %{ $self->_Column_Names() }, 'category' ],
        join     => 'Ninkasi::FlightCategory',
        order_by => 'number',
        where    => 'flight.rowid = flight_category.flight',
#       group_by => 'number',
    } );
#    $sth->bind_col( 1, \$result->{category} );

    # process the template, passing it a function to fetch flight data
    $template_object->process( 'flight.tt', {
        fetch_flight => sub { $sth->fetch() && $result },
        type         => $format,
    } ) or warn $template_object->error();

    return;
}

1;
