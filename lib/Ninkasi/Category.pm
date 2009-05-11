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


my @category_names = (
    'none',
    'Light Lager',
    'Pilsner',
    'European Amber Lager',
    'Dark Lager',
    'Bock',
    'Light Hybrid Beer',
    'Amber Hybrid Beer',
    'English Pale Ale',
    'Scottish and Irish Ale',
    'American Ale',
    'English Brown Ale',
    'Porter',
    'Stout',
    'India Pale Ale (IPA)',
    'German Wheat and Rye Beer',
    'Belgian and French Ale',
    'Sour Ale',
    'Belgian Strong Ale',
    'Strong Ale',
    'Fruit Beer',
    'Spice/Herb/Vegetable Beer',
    'Smoke-Flavored and Wood-Aged Beer',
    'Specialty Beer',
    'Unhopped Beer',
);

our @CATEGORIES = ();
foreach my $number (0..$#category_names) {
    push @CATEGORIES, {
        field_name => sprintf('category%02d', $number),
        name       => $category_names[$number],
        number     => $number,
    };
}

1;
