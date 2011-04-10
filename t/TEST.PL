use strict;
use warnings FATAL => 'all';

use lib qw(
);

use base 'Apache::TestRun';

use Cwd;
use File::Spec;

$ENV{NINKASI_TEST_SERVER_ROOT} = File::Spec->catfile(getcwd(), 't');

my $database_file = File::Spec->catfile( $ENV{NINKASI_TEST_SERVER_ROOT},
                                         'database' );
unlink $database_file;
my @init_command = ( File::Spec->catfile( getcwd(), qw/blib bin ninkasi-init/ ),
                     $database_file );
my $init_command_log = join( ' ', @init_command );
system(@init_command) == 0 or die "$init_command_log: $?";

# create new SQL log for every test run
unlink File::Spec->catfile( $ENV{NINKASI_TEST_SERVER_ROOT}, 'dbi.log' );

main::->new()->run(@ARGV);

sub pre_configure {
    my $self = shift;

    # Don't load buggy installed modules
    Apache::TestConfig::autoconfig_skip_module_add('mod_dav_svn.c');
    Apache::TestConfig::autoconfig_skip_module_add('mod_authz_svn.c');
}
