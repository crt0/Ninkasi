use strict;
use warnings;

use File::Spec;
use Smart::Comments;

use lib 'inc';
use MyBuilder;

our %RELPATH = (
    cgi   => 'cgi-bin',
    css   => File::Spec->catfile(qw/httpdocs css/),
    etc   => 'etc',
    share => File::Spec->catfile(qw/share ninkasi/),
);

my $build = MyBuilder->new(
    build_requires     => {
        'Class::Data::Inheritable' => '0.02',
        'Class::Singleton'         => '1.4',
        'DBD::SQLite'              => '1.11',
        'Data::Dumper'             => '2.121_08',
        'Data::UUID'               => '1.148',
        'Date::Format'             => '2.22',
        'LWP::UserAgent'           => '2.031',
        'Module::Build'            => '0.2808',
        'Object::InsideOut'        => '3.21',
        'Readonly'                 => '1.03',
        'Taint::Util'              => '0.06',
        'Template'                 => '2.19',
        'Test::WWW::Mechanize'     => '1.20',
    },
    create_makefile_pl => 'passthrough',
    create_readme      => 1,
    license            => 'perl',
    module_name        => 'Ninkasi',
);

foreach my $subdir (qw/cgi css share/) {
    $build->install_base_relpaths($subdir => $RELPATH{$subdir});
}

$build->add_build_element('css');
$build->add_build_element('share');
$build->add_build_element('tt');

$build->create_build_script();
