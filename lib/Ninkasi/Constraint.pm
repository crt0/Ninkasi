package Ninkasi::Constraint;

use strict;
use warnings;

use base 'Ninkasi::Table';

__PACKAGE__->Table_Name('constraint');
__PACKAGE__->Column_Names(qw/constraint_id category judge type/);
__PACKAGE__->Create_Sql(<<'EOF');
CREATE TABLE "constraint" (
    constraint_id TEXT PRIMARY KEY,
    category      INTEGER,
    judge         TEXT,
    type          INTEGER
)
EOF

our @CONSTRAINTS = (
    {
        name   => 'entry',
        number => 10,
    },
    {
        name   => 'prefer not',
        number => 20,
    },
    {
        name   => 'whatever',
        number => 30,
    },
    {
        name   => 'prefer',
        number => 40,
    },
);

our (%NAME, %NUMBER);
foreach my $constraint (@CONSTRAINTS) {
    $NAME  { $constraint->{number} } = $constraint->{name  };
    $NUMBER{ $constraint->{name  } } = $constraint->{number};
}

1;
