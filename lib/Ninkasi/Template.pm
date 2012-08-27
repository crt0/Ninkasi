package Ninkasi::Template;

use strict;
use warnings;

use base qw/Class::Singleton Template/;

use Class::Singleton;
use Ninkasi::Config;
use Template::Constants ':debug';

sub new { shift->instance(@_) }

sub _new_instance {
    my ( $class, $template_config ) = @_;

    $template_config ||= {};

    # some tables are larger than the default of 1000
    $Template::Directive::WHILE_MAX = 10_000;

    my $config = Ninkasi::Config->new();
    $template_config->{INCLUDE_PATH} = $config->get('template_path');

    return $class->SUPER::new($template_config);
}

sub process {
    my $self = shift;

    return $self->SUPER::process(@_) || die $self->error();
}

1;
__END__

=head1 NAME

Ninkasi::Template - Ninkasi front end to the Template Toolkit

=head1 SYNOPSIS

  use Ninkasi::Template;
  
  my $template_object = Ninkasi::Template->new();
  $template_object->process( $template_name, \%template_input );

=head1 DESCRIPTION

Ninkasi::Template is a wrapper for L<Template(3)> that does some
initial configuration pertinent to L<Ninkasi(3)>, such as setting
C<INCLUDE_PATH> to the Ninkasi template repository specified by the
C<template_path> configuration variable (see L<Ninkasi::Config(3)>).

=head1 SUBROUTINES/METHODS

This module is a subclass of L<Template(3)>.  It overrides the
constructor method for the reasons mentioned above, and also the
C<process> method, to make it throw an exception on error.

=head1 DIAGNOSTICS

If C<process> method encounters an error, it dies with the
L<Template(3)> error message.

=head1 CONFIGURATION

The following L<Ninkasi::Config(3)> variable C<template_path> is used
by this module to configure the L<Template> include path.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.  Please report problems to
Andrew Korty <andrew@korty.name>.  Patches are welcome.

=head1 AUTHOR

Andrew Korty <andrew@korty.name>

=head1 LICENSE AND COPYRIGHT

This software is in the public domain.

=head1 EXAMPLES

See the Ninkasi module and test source.

=head1 SEE ALSO

L<Ninkasi(3)>, L<Ninkasi::Config(3)>, L<Template(3)>
