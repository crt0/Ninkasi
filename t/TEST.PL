use strict;
use warnings FATAL => 'all';

use lib qw(
);

use Cwd;
use File::Spec;

$ENV{APACHE_TEST_PORT} = 8530;
$ENV{NINKASI_TEST_SERVER_ROOT} = File::Spec->catfile(getcwd(), 't');

my $database_file = File::Spec->catfile( $ENV{NINKASI_TEST_SERVER_ROOT},
                                         'database' );
unlink $database_file;
my @init_command = ( File::Spec->catfile( getcwd(), 'ninkasi-init' ),
                     $database_file );
my $init_command_log = join( ' ', @init_command );
warn "$init_command_log\n";
system(@init_command) == 0 or die "$init_command_log: $?";

# create new SQL log for every test run
unlink File::Spec->catfile( $ENV{NINKASI_TEST_SERVER_ROOT}, 'dbi.log' );

use Apache::TestRunPerl ();
Apache::TestRunPerl->new->run(@ARGV);
