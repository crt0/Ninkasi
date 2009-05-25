package Ninkasi::Flight;

use strict;
use warnings;

use base 'Ninkasi::Table';

use Ninkasi::Template;

__PACKAGE__->Table_Name('flight');
__PACKAGE__->Column_Names(qw/category description pro number/);
__PACKAGE__->Create_Sql(<<'EOF');
CREATE TABLE flight (
    category    INTEGER,
    description INTEGER,
    pro         INTEGER,
    number      INTEGER
)
EOF

sub update_flights {
    my ($cgi_object) = @_;

    # get a database handle
    my $dbh = __PACKAGE__->Database_Handle();

    # disable autocommit to perform this operation as one transaction
#     $dbh->{AutoCommit} = 0;

    # clear the table
    $dbh->do('DELETE FROM flight');

    # build table of input data
    my %input_table = ();
    my $permitted_column = __PACKAGE__->_Column_Names();
    foreach my $name ( $cgi_object->param() ) {
        my ( $column, $row ) = split /_/, $name;
        next unless exists $permitted_column->{$column};
        $input_table{$row}{$column} = $cgi_object->param($name);
    }

    # add the flights as submitted
    my $column_list = join ', ', keys %$permitted_column;
    my $sql = <<EOF;
INSERT INTO flight ($column_list) VALUES (?, ?, ?, ?)
EOF
    my $sth = $dbh->prepare($sql);
    while ( my ( $row_number, $row ) = each %input_table ) {
        $sth->execute( @$row{ keys %$permitted_column } );
    }

    # commit this transaction & re-enable autocommit
#     $dbh->commit();
#     $dbh->{AutoCommit} = 1;

    return;
}

sub render_page {
    my ($self, $cgi_object) = @_;

    # process input
    if ( $cgi_object->param('save') ) {
        update_flights $cgi_object;
    }

    # select whole table & order by number
    my $flight = Ninkasi::Flight->new();
    my ($sth, $result) = $flight->bind_hash( {
        columns => [ keys %{ $self->_Column_Names() } ],
        order   => 'number',
    } );

    # format parameter determines content type
    my $format = $cgi_object->param('format') || 'html';
    print $cgi_object->header($format eq 'html' ? 'text/html' : 'text/plain');

    # create template object for output
    my $template_object = Ninkasi::Template->new();

    # escape HTML but not for CSV output
    my $escape_html = sub { $format eq 'csv' ? sub { shift } : 'html_entity' };

    # process the template, passing it a function to fetch flight data
    $template_object->process( 'flight.tt', {
        escape_html  => $escape_html,
        fetch_flight => sub { $sth->fetch() && $result },
        type         => $format,
    } ) or warn $template_object->error();

    return;
}

1;
