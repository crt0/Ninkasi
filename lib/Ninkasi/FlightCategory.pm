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

__END__

=head1 NAME

Ninkasi::FlightCategory - mapping between flights and the categories they contain

=head1 SYNOPSIS

Used in the C<join> attribute to the C<bind_hash> method of the
L<Ninkasi::Table(3)> class and its subclasses.

=head1 DESCRIPTION

Ninkasi::FlightCategory provides an interface to a database table
mapping flights (L<Ninkasi::Flight(3)>) to BJCP categories
(L<Ninkasi::Category(3)>).

=head1 SUBROUTINES/METHODS

Ninkasi::FlightCategory is a subclass of L<Ninkasi::Table(3)>.  No
other subroutines or methods are defined.

=head1 ATTRIBUTES

The following attributes are represented as columns in the database
table:

=over 4

=item category (INTEGER)

L<Ninkasi::Category(3)> row id.

=item flight (INTEGER)

L<Ninkasi::Flight(3)> row id.

=back

=head1 CONFIGURATION

No L<Ninkasi::Config(3)> variables are used by this module.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.  Please report problems to
Andrew Korty <andrew.korty@icloud.com>.  Patches are welcome.

=head1 AUTHOR

Andrew Korty <andrew.korty@icloud.com>

=head1 LICENSE AND COPYRIGHT

This software is in the public domain.

=head1 SEE ALSO

L<Ninkasi(3)>, L<Ninkasi::Category(3)>, L<Ninkasi::Flight(3)>,
L<Ninkasi::Table(3)>
