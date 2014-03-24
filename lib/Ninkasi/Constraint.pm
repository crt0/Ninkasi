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
__END__

=head1 NAME

Ninkasi::Constraint - mapping of judges to constraints for each category

=head1 SYNOPSIS

  use Ninkasi::Constraint;

  # get number associated with "prefer" constraint
  print "prefer: $Ninkasi::Constraint::NUMBER{prefer}\n";

  # get constraint name associated with the number 2 (
  print "constraint 2: $Ninkasi::Constraint::NAME{2}\n";

=head1 DESCRIPTION

Ninkasi::Constraint provides an interface to a database table of
assignments of judges (see L<Ninkasi::Volunteer(3)>) to categories
(see L<Ninkasi::Category(3)>) to constraint types for each judging
session.  The current constraint types are

  NAME        NUMBER  DESCRIPTION
  ----        ------  -----------
  prefer           1  prefers to judge this category
  whatever         2  has no strong feelings on judging this category
  prefer not       4  prefers not to judge this category
  entry            8  has an entry in this category and can't judge it

The NUMBER indicates the number used to indicate a given constraint in
the database.  Multiple constraints cannot yet be specified, but the
numbers were chosen as powers of two to allow such a feature in the
future.

=head1 METHODS

Ninkasi::Constraint is a subclass of L<Ninkasi::Table(3)>.  No
additional methods are defined.

=head1 ATTRIBUTES

The following attributes are represented as columns in the database
table:

=over 4

=item category (INTEGER)

BJCP category to which constraint applies (see L<Ninkasi::Category(3)>
and the
L<2008 BJCP Style Guidelines|http://www.bjcp.org/2008styles/catdex.php>).

=item type (INTEGER)

Constraint type (see table above in L</DESCRIPTION>).

=item volunteer (INTEGER)

Judge to which constraint applies (see L<Ninkasi::Judge(3)> and
L<Ninkasi::Volunteer(3)>).

=back

=head1 DIAGNOSTICS

If this module encounters an error while rendering a template,
C<Ninkasi::Template->error()> is called to generate a warning message
that is printed on C<STDERR>.

=head1 CONFIGURATION

No L<Ninkasi::Config(3)> variables are used by this module.

=head1 BUGS AND LIMITATIONS

Because C<constraint> is a reserved word in SQLite, it must be quoted
when used as a table name in any SQL statements.

Please report problems to Andrew Korty <andrew.korty@icloud.com>.  Patches
are welcome.

=head1 AUTHOR

Andrew Korty <andrew.korty@icloud.com>

=head1 LICENSE AND COPYRIGHT

This software is in the public domain.

=head1 EXAMPLES

See the C<fetch> method of L<Ninkasi::Flight(3)> for an example of
fetching flights of each constraint type.

=head1 SEE ALSO

L<Ninkasi(3)>, L<Ninkasi::Category(3)>, L<Ninkasi::Flight(3)>,
L<Ninkasi::Table(3)>, L<Ninkasi::Volunteer(3)>
