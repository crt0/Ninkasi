package Ninkasi::Table;

use strict;
use warnings;

use base 'Class::Data::Inheritable';

use Carp qw/confess/;
use DBI;
use Ninkasi::Config;

__PACKAGE__->mk_classdata('Database_Handle');
__PACKAGE__->mk_classdata('_Column_Names');
__PACKAGE__->mk_classdata('Table_Name');
__PACKAGE__->mk_classdata('Schema');

sub import {
    my ($class) = @_;

    if ( !$class->Database_Handle() ) {
        my $config = Ninkasi::Config->new();
        my $database_file = $config->database_file();
        my $dbh = DBI->connect( "dbi:SQLite:dbname=$database_file", '', '',
                                { HandleError => sub { confess shift },
                                  RaiseError  => 1 } );
        $class->Database_Handle($dbh);

        # enable tracing during testing
        if ( $ENV{NINKASI_TEST_SERVER_ROOT} ) {
            $dbh->trace( 1, File::Spec->catfile( $ENV{NINKASI_TEST_SERVER_ROOT},
                                                 'dbi.log' ) );
        }
    }
}

sub new { bless [], shift }

sub add {
    my ($self, $column) = @_;

    my $table_name = $self->Table_Name();
    my @column_names = $self->columns_to_update($column);
    my $column_name_list = join ', ', @column_names;
    my $placeholders = join ', ', ('?') x @column_names;
    my $sth = $self->Database_Handle()->prepare(<<EOF);
INSERT INTO $table_name ($column_name_list) VALUES ($placeholders)
EOF
    $sth->execute( @$column{ @column_names } );

    return $self->Database_Handle()->last_insert_id( (undef) x 4 );
}

sub get_one_row {
    my ( $self, $argument ) = @_;

    # run the query and get one row
    my ( $statement_handle, $result ) = $self->bind_hash($argument);
    $statement_handle->fetch();

    # get results in order requested
    my @results = @$result{ @{ $argument->{columns} } };

    # release the statement handle
    $statement_handle->finish();

    return @results;
}

# supported SQL clauses in the order we want them to appear in queries
my @CLAUSES = qw/where limit group_by having order_by/;

# thank you chromatic
sub bind_hash {
    my ($self, $argument) = @_;

    # unpack arguments
    my @columns     = @{ $argument->{ columns     } } ;
    my @bind_values = ();
    if ( exists $argument->{ bind_values } ) {
        @bind_values = @{ $argument->{ bind_values } };
    }

    # prepare and execute SQL
    my $column_list = join ', ', @columns;
    my $table = $self->Table_Name();

    # format table list
    my $table_list;
    my $dbh = $self->Database_Handle();
    if (exists $argument->{join}) {
        $table_list = join ' JOIN ', $table,
            ref $argument->{join}
                ? map { $_->Table_Name() } @{ $argument->{join} }
                : $argument->{join}->Table_Name();
    }
    else {
        $table_list = $table;
    }

    my $sql = <<EOF;
SELECT $column_list FROM $table_list
EOF

    # add clauses
    foreach my $clause (@CLAUSES) {
        if ( exists $argument->{$clause} ) {

            # e.g., order_by -> 'ORDER BY'
            ( my $keyword = $clause ) =~ tr/_/ /;

            $sql = join ' ', $sql, uc $keyword, $argument->{$clause};
        }
    }

    my $sth = $self->Database_Handle()->prepare($sql);
    $sth->execute(@bind_values);

    # bind the values of a hash to column values
    my %results;
    @results{@columns} = ();
    $sth->bind_columns( map { \$results{$_} } @columns );

    return ( $sth, \%results );
}

sub Column_Names {
    my ($class, @names) = @_;

    my %names_hash;
    @names_hash{@names} = @names;
    $class->_Column_Names( \%names_hash );

    return;
}

sub columns_to_update {
    my ($self, $input_column) = @_;

    my $column_names = $self->_Column_Names();

    return grep { exists $column_names->{$_} } keys %$input_column;
}

1;
