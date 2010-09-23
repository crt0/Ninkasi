package Ninkasi::FlightCategory;

use strict;
use warnings;

use base 'Ninkasi::Table';

__PACKAGE__->Table_Name('flight_category');
__PACKAGE__->Column_Names( [ qw/category flight/ ] );
__PACKAGE__->Schema(<<'EOF');
CREATE TABLE flight_category (
    category INTEGER,
    flight   INTEGER
)
EOF

1;
