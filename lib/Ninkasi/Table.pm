package Ninkasi::Table;

use strict;
use warnings;

use base 'Class::Data::Inheritable';

use DBI;
use Ninkasi::Config;
use Smart::Comments;

__PACKAGE__->mk_classdata('Database_Handle');
__PACKAGE__->mk_classdata('_Column_Names');
__PACKAGE__->mk_classdata('Table_Name');
__PACKAGE__->mk_classdata('Create_Sql');

sub import {
    my ($class) = @_;

    my $config = Ninkasi::Config->new();
    my $database_file = $config->database_file();
    my $dbh = DBI->connect("dbi:SQLite:dbname=$database_file", '', '',
                           { RaiseError => 1 });
    $class->Database_Handle($dbh);

    # create table in case it doesn't already exist
    my $create_sql = $class->Create_Sql();
    if ($create_sql) {
        eval {
            local $dbh->{PrintError};
            $dbh->do($create_sql);
        };
        die $@ if $@ && $@ !~ /already exists/;
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
    my $table_list = exists $argument->{join}
                   ? "$table JOIN " . $argument->{join}->Table_Name()
                   : $table
                   ;

    my $sql = <<EOF;
SELECT $column_list FROM $table_list
EOF

    if ( exists $argument->{where} ) {
        $sql .= " WHERE $argument->{where}";
    }

    if ( exists $argument->{order} ) {
        $sql .= " ORDER BY $argument->{order}";
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

sub create_table {
    my ($self) = @_;

    return $self->Database_Handle()->do( $self->Create_Sql() );
}

1;
