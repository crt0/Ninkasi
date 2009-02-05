package Ninkasi::Template;

use strict;
use warnings;

use base qw/Class::Singleton Template/;

use Class::Singleton;
use Ninkasi::Config;
use Smart::Comments;

sub new { shift->instance(@_) }

sub _new_instance {
    my ($class, $template_config) = @_;

    my $config = Ninkasi::Config->new();
    $template_config->{INCLUDE_PATH} = $config->get('template_path');
    my $self = $class->SUPER::new($template_config);

    return $self;
}

1;
