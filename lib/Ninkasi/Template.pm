package Ninkasi::Template;

use strict;
use warnings;

use base qw/Class::Singleton Template/;

use Class::Singleton;
use Ninkasi::Config;
use Smart::Comments;

sub new { shift->instance(@_) }

sub _new_instance {
    my $class = shift;

    my $config = Ninkasi::Config->new();
    my $self = $class->SUPER::new( {
        INCLUDE_PATH => $config->get('template_path'),
    } );

    return $self;
}

1;
