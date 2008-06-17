package MyBuilder;

use strict;
use warnings;

use File::Spec;
use Smart::Comments;

BEGIN {
    our @ISA = eval { require Apache::TestMB }
             ? 'Apache::TestMB'
             : 'Module::Build'
             ;
}

# copy a subdirectory into blib/
sub process_dir {
    my ($self, $type_subdir, $destination) = @_;

    $destination ||= $self->blib();
    my $files_to_copy = $self->rscan_dir( $type_subdir,
                                          sub { -f && !m{/#} && !m{~$} } );
    foreach my $file (@$files_to_copy) {
        $self->copy_if_modified( $file, $destination )
            or next;
    }
}

sub process_css_files   { shift->process_dir( 'css'   ) }
sub process_etc_files   { shift->process_dir( 'etc'   ) }
sub process_share_files { shift->process_dir( 'share' ) }

# find files to process with the Template Toolkit
sub find_tt_files {
    my ($self) = @_;

    my %tt_files = (
        %{ $self->_find_file_by_type('tt', 'cgi') },
        %{ $self->_find_file_by_type('tt', 'lib') },
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
    while (my ($type, $path_components)
               = each %{ $self->install_base_relpaths() }) {
        $install_base_relpath{$type} = File::Spec->catfile(@$path_components);
    }

    # process Template files
    require Template;
    my $template = Template->new();
    my $tt_files = $self->find_tt_files();
    my %template_variables = (
        install_base          => $self->install_base(),
        install_base_relpath  => \%install_base_relpath,
    );
    while ( my ($source, $destination) = each %$tt_files ) {
        my $blib_destination = File::Spec->catfile( $self->blib(),
                                                    $destination );
        $template->process($source, \%template_variables, $blib_destination)
            or die $template->error();
        $self->make_executable($blib_destination);
        print "Processing $source -> $blib_destination\n";
    }
}

1;
