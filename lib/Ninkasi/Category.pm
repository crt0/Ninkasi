package Ninkasi::Category;

use strict;
use warnings;

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
);

our @CATEGORIES = ();
foreach my $number (0..$#category_names) {
    push @CATEGORIES, {
        field_name => sprintf('category%02d', $number),
        name       => $category_names[$number],
        number     => $number,
    };
}

push @CATEGORIES, {
    field_name => 'category99',
    name       => 'Indiana Indigenous Beer',
    number     => 99,
};

1;

__END__

=head1 NAME

Ninkasi::Category - a table of BJCP style category names

=head1 SYNOPSIS

  use Ninkasi::Category;
  
  foreach $category (@Ninkasi::Category::CATEGORIES) {
      print "$category->{number}. $category->{name}\n";
  }

=head1 DESCRIPTION

Ninkasi::Category contains a list of style categories as presented by
the L<2008 Beer Judge Certification Program Style
Guidelines|http://www.bjcp.org/2008styles/catdex.php>.  An ordered
list of the categories, C<@CATEGORIES>, is exported.  Each element is
a hash reference with the following elements:

  name        the category name (I<e.g.>, I<Light Lager>)
  number      the cardinal number corresponding to the category
  field_name  a query parameter name of the form C<categoryNN>, where
              C<NN> is the category number (likely only used
              internally)

=head1 SUBROUTINES/METHODS

None.

=head1 CONFIGURATION

No L<Ninkasi::Config(3)> variables are used by this module.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.  Please report problems to
Andrew Korty <andrew@korty.name>.  Patches are welcome.

=head1 AUTHOR

Andrew Korty <andrew@korty.name>

=head1 LICENSE AND COPYRIGHT

This software is in the public domain.

=head1 SEE ALSO

L<Ninkasi(3)>
