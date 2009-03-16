package Ninkasi::Category;

use strict;
use warnings;

use base 'Ninkasi::Table';

__PACKAGE__->Table_Name('category');
__PACKAGE__->Column_Names(qw/number flight judge/);
__PACKAGE__->Create_Sql(<<'EOF');
CREATE TABLE category (
    number INTEGER,
    flight INTEGER,
    judge  INTEGER
)
EOF

1;
