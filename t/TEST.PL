use strict;
use warnings FATAL => 'all';

use lib qw(
);

use Cwd;
use File::Spec;

$ENV{NINKASI_TEST_SERVER_ROOT} = File::Spec->catfile(getcwd(), 't');

use Apache::TestRunPerl ();
Apache::TestRunPerl->new->run(@ARGV);
