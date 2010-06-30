package Ninkasi::Constraint;

use strict;
use warnings;

use base 'Ninkasi::Table';

__PACKAGE__->Table_Name("'constraint'");
__PACKAGE__->Column_Names(qw/category judge type/);
__PACKAGE__->Schema(<<'EOF');
CREATE TABLE "constraint" (
    category      INTEGER,
    judge         INTEGER,
    type          INTEGER
)
EOF

our @CONSTRAINTS = (
    { name => 'prefer',     number => 0b0001 },
    { name => 'whatever',   number => 0b0010 },
    { name => 'prefer not', number => 0b0100 },
    { name => 'entry',      number => 0b1000 },
);

our (%NAME, %NUMBER);
foreach my $constraint (@CONSTRAINTS) {
    $NAME  { $constraint->{number} } = $constraint->{name  };
    $NUMBER{ $constraint->{name  } } = $constraint->{number};
}

sub fetch {
    my ($judge_id) = @_;

    # fetch constraints for the specified judge
    my $constraint = Ninkasi::Constraint->new();
    my ($sth, $result) = $constraint->bind_hash( {
        bind_values => [$judge_id],
        columns     => [qw/category type/],
        order_by    => 'category',
        where       => 'judge = ?',
    } );

    # intialize a hash to store the constraint lists (indexed by type name)
    my %constraint = ();

    # build an index of missing rows (we'll remove the categories we find)
    my %not_found  = ();
    @not_found{ 1 .. $#Ninkasi::JudgeSignup::CATEGORIES } = ();

    # walk the rows, building constraint lists
    while ( $sth->fetch() ) {

        # add this category to the appropriate constraint list
        push @{ $constraint{ $Ninkasi::Constraint::NAME{ $result->{type} } } },
             $result->{category};

        # we found a constraint for this category, so delete it from %not_found
        delete $not_found{ $result->{category} };
    }

    # add any missing rows to the 'whatever' list
    @{ $constraint{whatever} }
        = sort { $a <=> $b } keys %not_found, @{ $constraint{whatever} || [] };

    # return the hash of constraint lists
    return \%constraint;
}

1;
