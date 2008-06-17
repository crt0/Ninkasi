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
    judge         INTEGER,
    type          TEXT
)
EOF

1;
