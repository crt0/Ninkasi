package MyBuilder;

use strict;
use warnings;

use Config;
use File::Basename;
use File::Spec;

BEGIN {
    our @ISA = eval { require Apache::TestMB }
             ? 'Apache::TestMB'
             : 'Module::Build'
             ;
}

# copy a subdirectory into blib/
sub process_dir {
    my ($self, $type_subdir, $want_tt_files) = @_;

    my $files_to_copy = $self->rscan_dir(
        $type_subdir, sub { -f && !m{/\.svn/}
                               && !m{/#}
                               && !m{~$}
                               && ( $want_tt_files || !m{\.tt$} ) }
    );
    foreach my $file (@$files_to_copy) {
        $self->copy_if_modified( $file, $self->blib() )
            or next;
    }
}

sub process_htdocs_files { shift->process_dir('htdocs'  ) }
sub process_share_files  { shift->process_dir('share', 1) }

# find files to process with the Template Toolkit
sub find_tt_files {
    my ($self) = @_;

    my %tt_files = (
        %{ $self->_find_file_by_type('tt', 'bin'   ) },
        %{ $self->_find_file_by_type('tt', 'htdocs') },
        %{ $self->_find_file_by_type('tt', 'lib'   ) },
    );
    foreach my $source (keys %tt_files) {
        $tt_files{$source} =~ s/\.tt$//;
    }

    return \%tt_files;
}

# process .tt files with the Template Toolkit
sub process_tt_files {
    my ($self) = @_;

    # determine paths
    my %install_base_relpath = ();
    my $mb_relpaths = $self->install_base_relpaths();
    while ( my ( $type, $path_components ) = each %$mb_relpaths ) {
        $install_base_relpath{$type} = File::Spec->catfile(@$path_components);
    }

    # process Template files
    require Template;
    my $template = Template->new( {
        INCLUDE_PATH => File::Spec->catfile(qw/share template/) . ':.' } );
    my $tt_files = $self->find_tt_files();
    my %template_variables = (
        apostrophe            => '&#8217;',
        install_base          => $self->install_base(),
        install_base_relpath  => \%install_base_relpath,
        scriptdir             => $Config{scriptdir},
        year                  => 1900 + (localtime)[5],
    );
    while ( my ($source, $destination) = each %$tt_files ) {
        my $page_name = basename $source, '.tt';
        if ( $page_name eq 'index' ) {
            $page_name = '';
        }
        my $blib_destination = File::Spec->catfile( $self->blib(),
                                                    $destination );
        $template->process( $source,
                            { %template_variables, page => $page_name },
                            $blib_destination )
            or die $template->error();
        $self->make_executable($blib_destination);
        print "Processing $source -> $blib_destination\n";
    }
}

1;
