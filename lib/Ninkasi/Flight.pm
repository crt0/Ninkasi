package Ninkasi::Flight;

use strict;
use warnings;

use base 'Ninkasi::Table';

use Ninkasi::Template;

__PACKAGE__->Table_Name('flight');
__PACKAGE__->Column_Names(qw/category description pro number/);
__PACKAGE__->Schema(<<'EOF');
CREATE TABLE flight (
    category    INTEGER,
    description INTEGER,
    pro         INTEGER DEFAULT 0,
    number      TEXT UNIQUE
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
    my $sql = <<EOF;
judge.rowid = 'constraint'.judge
    AND 'constraint'.judge = ?
    AND 'constraint'.category = flight.category
    AND (type != ? OR judge.pro_brewer = flight.pro)
EOF
    my $entry = $Ninkasi::Constraint::NUMBER{entry};
    my ( $flight_handle, $flight ) = $flight_table->bind_hash( {
        bind_values => [ $judge_id, $entry ],
        columns     => [ qw/flight.category number type/ ],
        join        => [ qw/Ninkasi::Constraint Ninkasi::Judge/ ],
        order       => 'number',
        where       => $sql,
    } );
    $flight_handle->bind_col( 1, \$flight->{category} );

    # intialize a hash to store the constraint lists (indexed by type name)
    my %constraint = ();

    # walk the rows, building constraint lists
    while ( $flight_handle->fetch() ) {

        # add this flight to the appropriate constraint list
        push @{ $constraint{ $Ninkasi::Constraint::NAME{ $flight->{type} } } },
             $flight->{number};

        # we found a constraint for this category, so delete it from $not_found
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
    $dbh->{AutoCommit} = 0;

    # clear the table
    $dbh->do('DELETE FROM flight');

    # build table of input data
    my %input_table = ();
    my $permitted_column = __PACKAGE__->_Column_Names();
    foreach my $name ( $cgi_object->param() ) {
        my ( $column, $row ) = split /_/, $name;
        next if !exists $permitted_column->{$column};
        $input_table{$row}{$column} = $cgi_object->param($name);
    }

    # add the flights as submitted
    my $column_list = join ', ', keys %$permitted_column;
    my $sql = <<EOF;
INSERT INTO flight ($column_list) VALUES (?, ?, ?, ?)
EOF
    my $sth = $dbh->prepare($sql);
    while ( my ( $row_number, $flight ) = each %input_table ) {
        next if !defined $flight->{number} || $flight->{number} eq '';
        $flight->{pro} ||= 0;
        eval { $sth->execute( @$flight{ keys %$permitted_column } ) };
        if ($@) {
            $dbh->rollback();
            $dbh->{AutoCommit} = 1;
            my $message = $@ =~ /column number is not unique/
                        ? 'Flight numbers must be unique.'
                        : $@
                        ;
            return { row => $flight->{number}, message => $message };
        }
    }

    # commit this transaction & re-enable autocommit
    $dbh->commit();
    $dbh->{AutoCommit} = 1;

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
    print $cgi_object->header( $format eq 'html' ? 'text/html' : 'text/plain' );

    # create template object for output
    my $template_object = Ninkasi::Template->new();

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
        columns => [ keys %{ $self->_Column_Names() } ],
        order   => 'category, number',
    } );

    # process the template, passing it a function to fetch flight data
    $template_object->process( 'flight.tt', {
        fetch_flight => sub { $sth->fetch() && $result },
        type         => $format,
    } ) or warn $template_object->error();

    return;
}

1;
