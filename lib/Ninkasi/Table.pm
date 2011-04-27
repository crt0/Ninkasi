package Ninkasi::Table;

use strict;
use warnings;

use base 'Class::Data::Inheritable';

use Carp qw/confess/;
use DBI;
use Ninkasi::Config;

__PACKAGE__->mk_classdata('Class_Suffixes');
__PACKAGE__->mk_classdata('_Column_Names');
__PACKAGE__->mk_classdata('Column_Names_Hash');
__PACKAGE__->mk_classdata('Schema');
__PACKAGE__->mk_classdata('Table_Name');

__PACKAGE__->Class_Suffixes( [ qw/Assignment Constraint Flight FlightCategory
                                  MailingList Volunteer/ ] );

sub new {
    my ($self) = @_;

    return bless [], ref $self || $self;
}

sub initialize_database {
    my ( $class, $argument ) = @_;

    my $config = Ninkasi::Config->new();

    if ( $argument->{unlink} && $ENV{NINKASI_TEST_SERVER_ROOT} ) {
        unlink $config->database_file();
    }

    # create database and tables
    my $database_handle = $class->Database_Handle();
    foreach my $class_suffix ( @{ $class->Class_Suffixes() } ) {
        my $table_class = "Ninkasi::$class_suffix";
        eval "require $table_class";
        confess $@ if $@;
        local $database_handle->{PrintError};
        local $database_handle->{RaiseError};
        $database_handle->do( $table_class->Schema() )
            or confess "$table_class: ", $database_handle->errstr();
    }

    return;
}

sub add {
    my ($self, $column) = @_;

    my $dbh = $self->Database_Handle();
    my $table_name = $self->Quoted_Table_Name();
    my @column_names = $self->columns_to_update($column);
    my $column_name_list = join ', ', map { $dbh->quote_identifier($_) }
                                          @column_names;
    my $placeholders = join ', ', ('?') x @column_names;
    my $sth = $self->Database_Handle()->prepare(<<EOF);
INSERT INTO $table_name ($column_name_list) VALUES ($placeholders)
EOF
    $sth->execute( @$column{ @column_names } );

    return $self->Database_Handle()->last_insert_id( (undef) x 4 );
}

# supported SQL clauses in the order we want them to appear in queries
my @CLAUSES = qw/where limit group_by having order_by/;

sub prepare {
    my ( $self, $attribute ) = @_;

    # unpack attributes
    my $sql = $attribute->{sql};
    my @columns = @{ $attribute->{columns} };

    # build SQL statement if not provided
    if (!$sql) {
        my $dbh = $self->Database_Handle();
        my $column_list = join ', ', @columns;
        my $table = $self->Quoted_Table_Name();

        # format table list
        my $table_list;
        if ( exists $attribute->{join} ) {
            $attribute->{join_command} ||= 'JOIN';

            my @tables = ($table);
            if ( ref $attribute->{join} ) {
                push @tables, map { eval "require $_"; $_->Quoted_Table_Name() }
                                  @{ $attribute->{join} };
            }
            else {
                eval "require $attribute->{join}";
                push @tables, $attribute->{join}->Quoted_Table_Name();
            }

            $table_list = join " $attribute->{join_command} ", @tables;
        }
        else {
            $table_list = $table;
        }

        $sql = <<EOF;
SELECT $column_list FROM $table_list
EOF
    }

    # add clauses
    foreach my $clause (@CLAUSES) {
        if ( $attribute->{$clause} ) {

            # e.g., order_by -> 'ORDER BY'
            ( my $keyword = $clause ) =~ tr/_/ /;

            $sql = join ' ', $sql, uc $keyword, $attribute->{$clause};
        }
    }

    return $self->Database_Handle()->prepare($sql);
}

sub get_one_row {
    my ( $self, $argument ) = @_;

    # run the query and get one row
    $argument->{full_names} = 1;
    my ( $statement_handle, $result ) = $self->bind_hash($argument);
    $statement_handle->fetch();

    # get results in order requested
    my @results = @$result{ @{ $argument->{columns} } };

    # release the statement handle
    $statement_handle->finish();

    return @results;
}

# thank you chromatic
sub bind_hash {
    my ( $self, $attribute ) = @_;

    # unpack attributes
    my @columns = @{ $attribute->{columns} };
    my @bind_values = ();
    if ( exists $attribute->{bind_values} ) {
        @bind_values = @{ $attribute->{bind_values} };
    }

    my $sth = $self->prepare($attribute);
    $sth->execute(@bind_values);

    # bind the values of a hash to column values
    my %results;
    @results{@columns} = ();
    if ( $attribute->{full_names} ) {
        $sth->bind_columns( \@results{@columns} );
    }
    else {
        $sth->bind_columns( map { \$results{ ( split /\./, $_ )[-1] } }
                                @columns );
    }

    return ( $sth, \%results );
}

# override this accessor to update hash of column names
sub Column_Names {
    my ( $class, $names ) = @_;

    if ($names) {
        $class->_Column_Names($names);
        my %names_hash = ();
        @names_hash{@$names} = @$names;
        $class->Column_Names_Hash(\%names_hash);
    }

    return $class->_Column_Names();
}

sub Database_Handle {
    my ($class) = @_;

    my $config = Ninkasi::Config->new();

    my $database_file = $config->get('database_file');
    my $database_handle = DBI->connect_cached(
        "dbi:SQLite:dbname=$database_file", '', '',
        { HandleError => sub { confess shift },
          RaiseError  => 1 }
    );

    # log to dbi.log while testing
    if ( my $test_directory = $config->get('test_server_root') ) {
        $database_handle->trace( 1,
                                 File::Spec->catfile( $test_directory,
                                                      'dbi.log' ) );
    }

    return $database_handle;
}

sub Quoted_Table_Name {
    my ($self) = @_;

    local $SIG{__DIE__} = \&confess;

    return $self->Database_Handle()->quote_identifier( $self->Table_Name() );
}

sub columns_to_update {
    my ( $self, $input_column ) = @_;

    my $column_names = $self->Column_Names_Hash();

    return grep { exists $column_names->{$_} } keys %$input_column;
}

1;

__END__

=head1 NAME

Ninkasi::Table - superclass for accessing SQLite tables

=head1 SYNOPSIS

    package Ninkasi::ExampleClass;
    
    use base 'Ninkasi::Table';
    
    __PACKAGE__->Table_Name('example_table');
    __PACKAGE__->Column_Names( qw/column1 column2 column3/ );
    __PACKAGE__->Schema(<<'EOF');
 CREATE TABLE example_table (
     column1 INTEGER,
     column2 TEXT,
     column3 INTEGER
 )
 EOF
    
    my $example_table = Ninkasi::ExampleClass->new();
    
    # add a row
    $example_table->add( { column1 => 17, column2 => 'twenty-three' } );
    
    # select rows, doing a LEFT OUTER JOIN
    my ( $statement_handle, $result ) = $example_table->bind_hash( {
        columns      => [ qw/column1 column3 another_table.column4/ ],
        limit        => 5,
        join         => 'Ninkasi::AnotherClass',
        join_command => 'LEFT OUTER JOIN',
        order        => 'column2',
        where        => 'example_table.column1 = another_table.rowid'
    } );
    $statement_handle->bind_col( 3, \$result->{column4} );
    while ( $statement_handle->fetch() ) {
        print <<EOF;
VALUES: $result->{column1}, $result->{column3}, $result->{column4}
 EOF
    }

=head1 DESCRIPTION

Ninkasi::Table provides class and instance methods to access an
SQLite database.

=head1 METHODS

=head2 Class Data Methods

=over 4

=item Class_Suffixes

Class method that returns a list all of Ninkasi(3)'s relative class
names (C<Feed>, C<Entry>, etc.).

=item Database_Handle($handle)

Set the current DBI(3) database handle to C<$handle>.  When C<$handle>
is undefined, return the current database handle.

=item Table_Name($table_name)

Set the class's table name to the string C<$table_name>.  When
C<$table_name> is undefined, return the class's table name.

=item Schema($sql)

Set this class's schema, in the form of an SQL C<CREATE TABLE>
statement, to the string C<$sql>.  When C<$sql> is undefined, return
the class's schema.

=back

=head2 Instance Methods

=over 4

=item new()

Create a new object for accessing the table.

=item init($database_filename)

Create a new SQLite database in the file named by
C<$database_filename> using the Ninkasi(3) schema.

=item add(\%column_data)

Add a row made from the column => value hash C<%column_data> to the
table using C<INSERT>.

=item bind_hash(\%argument)

Prepare a C<SELECT> statement using parameters specified in
C<%argument> (according to L</"Query Building"> below) and return a
hash reference containing the column data.

=back

=head2 Query Building

The following key => value pairs can be passed to C<bind_hash> in a
hash reference to control the resulting C<SELECT> query.

=over 4

=item columns => \@column_names

Specify a list of column names to return in the result hash.

=item join => $classes

Perform a join with the table(s) represented by C<$classes>, which can
be a string containing a single class name or a reference to an array
of class names for a multi-way join.

=item join_command => $sql

Specify SQL keyword(s) used for the join, if different than C<JOIN>.

=item limit => $number_of_rows

Limit the result set to an integral $number_of_rows using C<LIMIT>.

=item order => $column_name

Sort rows based on the values in the column named by C<$column_name>
using C<ORDER BY>.

=item where => $where_clause

Filter rows based on the logical SQL expression in the string
C<$where_clause>.

=back

=head1 DIAGNOSTICS

See L<DBI> for information on database errors that may occur.

The C<init()> method will throw an exception of C<$database_filename:
file exists\n>, where C<$database_filename> is the name of the
database file that was supposed to have been created, if that file
already exists.  It will also throw an exception if it encounters any
error while loading Ninkasi(3) classes to build the database
schema.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.  Please report problems to
Andrew Korty <ajk@iu.edu>.  Patches are welcome.

=head1 AUTHOR

Andrew Korty <ajk@iu.edu>

=head1 LICENSE AND COPYRIGHT

This software is in the public domain.

=head1 EXAMPLES

See the Ninkasi(3) module and test source.

=head1 ACKNOWLEDGMENTS

This module is based on ideas presented in a perl.com article by
chromatic entitled I<DBI is OK>,
L<http://www.perl.com/pub/a/2001/03/dbiokay.html>.

=head1 SEE ALSO

sqlite3(1), DBI(3), Ninkasi(3)
