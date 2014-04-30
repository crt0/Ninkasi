package Ninkasi::Judge;

use strict;
use warnings;

use base 'Ninkasi::Volunteer';

our @RANKS = (
    {
        description => 'Novice -- little or no judging experience',
        name        => 'Novice',
        number      => 10,
    },
    {
        description => 'Experienced but not in the BJCP',
        name        => 'Experienced',
        number      => 20,
    },
    {
        description => 'Provisional Judge',
        name        => 'Provisional',
        number      => 25,
    },
    {
        description => 'BCJP Apprentice',
        name        => 'Apprentice',
        number      => 30,
    },
    {
        description => 'BJCP Recognized',
        name        => 'Recognized',
        number      => 40,
    },
    {
        description => 'BJCP Certified',
        name        => 'Certified',
        number      => 50,
    },
    {
        description => 'BJCP National',
        name        => 'National',
        number      => 60,
    },
    {
        description => 'BJCP Master',
        name        => 'Master',
        number      => 70,
    },
    {
        description => 'BJCP Grand Master',
        name        => 'Grand Master',
        number      => 80,
    },
);

our ( %NAME, %NUMBER );
foreach my $rank (@RANKS) {
    $NAME  { $rank->{number} } = $rank->{name  };
    $NUMBER{ $rank->{name  } } = $rank->{number};
}

1;
__END__

=head1 NAME

Ninkasi::Judge - BJCP judge rank information

=head1 SYNOPSIS

  use Ninkasi::Judge;

  # transform user interface input into template input (really only
  # called by Ninkasi(3))
  $transform_results = Ninkasi::Judge->transform( {
      \%options,
      -positional => \%positional_parameters,
  } );
  Ninkasi::Template->new()->process( judge => $transform_results);

  # print sorted list of ranks and descriptions
  foreach $rank (@Ninkasi::Judge::RANKS) {
      print "$rank->{name}: $category->{description}\n";
  }

  # print sort key associated with Certified rank
  print "$Ninkasi::Judge::NUMBER{Certified}\n";

  # print rank associated with sort key 70
  print "$Ninkasi::Judge::NAME{70}\n";

=head1 DESCRIPTION

Ninkasi::Judge contains a list of BJCP ranks as defined in
the L<Beer Judge Certification Program Membership
Guide|http://www.bjcp.org/membergd.php#rank>.  An ordered
list of the ranks, C<@RANKS>, is exported.  Each element is
a hash reference with the following elements:

  name         the rank name (I<e.g.>, I<National>)
  number       a numeric sort key indicating the rank level
  description  a brief description of the rank

=head1 SUBROUTINES/METHODS

None.

=head1 CONFIGURATION

No L<Ninkasi::Config(3)> variables are used by this module.

=head1 BUGS AND LIMITATIONS

While this module inherits from L<Ninkasi::Volunteer(3)>, it doesn't
act as a subclass in any useful way except to inherit C<transform()>.

Please report problems to Andrew Korty <andrew.korty@icloud.com>.  Patches
are welcome.

=head1 AUTHOR

Andrew Korty <andrew.korty@icloud.com>

=head1 LICENSE AND COPYRIGHT

This software is in the public domain.

=head1 SEE ALSO

L<Ninkasi(3)>, L<Ninkasi::Volunteer(3)>
