use strict;
use warnings FATAL => 'all';

use base 'Apache::TestRun';

use Cwd;
use File::Spec;

# set server root environment variable for scripts
$ENV{NINKASI_TEST_SERVER_ROOT} = File::Spec->catfile(getcwd(), 't');

# create new SQL log for every test run
unlink File::Spec->catfile( $ENV{NINKASI_TEST_SERVER_ROOT}, 'dbi.log' );

# create new config file for every test run
unlink File::Spec->catfile( $ENV{NINKASI_TEST_SERVER_ROOT},
                            qw/conf ninkasi.conf/ );

main::->new()->run( @ARGV );

sub pre_configure {
    my $self = shift;

    # Don't load buggy/conflicting installed modules
    Apache::TestConfig::autoconfig_skip_module_add('mod_authz_svn.c');
    Apache::TestConfig::autoconfig_skip_module_add('mod_dav_svn.c');
    Apache::TestConfig::autoconfig_skip_module_add('mod_fcgid.c');
    Apache::TestConfig::autoconfig_skip_module_add('mod_php5.c');

    $self->SUPER::pre_configure($@);
}
