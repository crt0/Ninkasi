package Ninkasi::Constraint;

use strict;
use warnings;

use base 'Ninkasi::Table';

__PACKAGE__->Table_Name('constraint');
__PACKAGE__->Column_Names( [ qw/category volunteer type/ ] );
__PACKAGE__->Schema(<<'EOF');
CREATE TABLE "constraint" (
    category  INTEGER,
    volunteer INTEGER,
    type      INTEGER
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

1;
