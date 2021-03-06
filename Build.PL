use strict;
use warnings;

use File::Spec;

use lib 'inc';
use MyBuilder;

our %RELPATH = (
    htdocs => 'httpdocs',
    share  => File::Spec->catfile(qw/share ninkasi/),
);

my $build = MyBuilder->new(
    build_requires     => {
        'AppConfig'                => 0,
        'CGI::Simple'              => 0,
        'Class::Data::Inheritable' => '0.02',
        'Class::Singleton'         => '1.4',
        'DBD::SQLite'              => '1.13',
        'Data::Dumper'             => '2.121_08',
        'Data::UUID'               => 0,
        'Date::Format'             => '2.22',
        'Email::Address'           => '1.889',
        'File::LibMagic'           => 0,
        'Getopt::Euclid'           => 0,
        'HTML::Lint'               => 0,
        'Module::Build'            => '0.31',
        'Mouse'                    => 0,
        'Readonly'                 => '1.03',
        'Taint::Util'              => '0.06',
        'Template'                 => '2.19',
        'Test::WWW::Mechanize'     => '1.20',
    },
    create_makefile_pl => 'passthrough',
    create_readme      => 1,
    license            => 'perl',
    module_name        => 'Ninkasi',
    ninkasi_date1      => 'Friday, July 11',
    ninkasi_date2      => 'Saturday, July 12',
);

$build->require_external_program('groff' );
$build->require_external_program('ps2pdf');

foreach my $subdir (keys %RELPATH) {
    $build->install_base_relpaths( $subdir => $RELPATH{$subdir} );
}

$build->add_build_element('htdocs');
$build->add_build_element('share' );
$build->add_build_element('tt'    );

$build->create_build_script();
