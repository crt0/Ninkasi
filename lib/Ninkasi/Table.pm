package Ninkasi::Table;

use strict;
use warnings;

use base 'Class::Data::Inheritable';

use DBI;
use Data::UUID;
use Ninkasi::Config;
use Smart::Comments;

__PACKAGE__->mk_classdata('Database_Handle');
__PACKAGE__->mk_classdata('_Column_Names');
__PACKAGE__->mk_classdata('Table_Name');
__PACKAGE__->mk_classdata('Create_Sql');

sub new {
    my ($class) = @_;

    my $self = [];

    my $config = Ninkasi::Config->new();
    my $database_file = $config->database_file();
    __PACKAGE__->Database_Handle(
        DBI->connect("dbi:SQLite:dbname=$database_file", '', '',
                     { RaiseError => 1 })
    );

    return bless $self, $class;
}

sub add {
    my ($self, $column) = @_;

    # store UUID in primary key (table name with '_id' appended)
    my $primary_key = $self->Table_Name() . '_id';
    $column->{$primary_key} ||= Data::UUID->new()->create_b64();

    my $table_name = $self->Table_Name();
    my @column_names = $self->columns_to_update($column);
    my $column_name_list = join ', ', @column_names;
    my $placeholders = join ', ', ('?') x @column_names;
    my $sth = $self->prepare(<<EOF);
INSERT INTO '$table_name' ($column_name_list) VALUES ($placeholders)
EOF
    $sth->execute( @$column{ @column_names } );

    return $column->{judge_id};
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
                   ? '(' . join(', ', $table,
                                      map { q{'"} . $_->Table_Name() . q{"'} }
                                          @{ $argument->{join} })
                         . ')'
                   : "'$table'"
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

sub prepare {
    my ($self, $sql) = @_;

    my $dbh = $self->Database_Handle();
    my $sth;
    for (;;) {
        $dbh->{PrintError} = 0;
        $sth = eval { $dbh->prepare($sql) };
        $dbh->{PrintError} = 1;
        if ($@) {
            if ($@ =~ /no such table/) {
                $self->create_table();
                next;
            }
            die $@;
        }
        last;
    }

    return $sth;
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
