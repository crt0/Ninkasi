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
