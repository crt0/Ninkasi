package Ninkasi::Steward;

use strict;
use warnings;

use base 'Ninkasi::Volunteer';

1;
__END__

=head1 NAME

Ninkasi::Steward - BJCP steward information (currently empty)

=head1 SYNOPSIS

  use Ninkasi::Steward;

  # transform user interface input into template input (really only
  # called by Ninkasi(3))
  $transform_results = Ninkasi::Steward->transform( {
      \%options,
      -positional => \%positional_parameters,
  } );
  Ninkasi::Template->new()->process( steward => $transform_results );

=head1 DESCRIPTION

Ninkasi::Steward is an empty subclass of L<Ninkasi::Volunteer(3)>.

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
