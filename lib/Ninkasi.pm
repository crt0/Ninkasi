package Ninkasi;

use 5.008008;
use strict;
use warnings;

use Carp;
use Getopt::Long;
use Ninkasi::CGI;
use Ninkasi::CSV;
use Ninkasi::Template;
use Readonly;
use Taint::Util;

our $VERSION = '0.01';

my %Page;
@Page{ qw/assignment flight judge register steward volunteer/ } = ();

Readonly my %error_message => (
    403 => "You don't have permission to access this portion of the site.",
    404 => "We couldn't find the page you requested.",
    500 => "There's a software error on our end.  Please try back later.",
);
Readonly my %error_title => (
    403 => 'Access Denied',
    404 => 'Not Found',
    500 => 'Software Error',
);

# template variables to propagate on error
Readonly my @error_variables => qw/categories field form ranks title/;

sub die_with_error_page {
    my ( $environment, $error, $template_object, $template_input ) = @_;

    $template_input ||= {};
    $error->{status} ||= 500;

    # send to browser if not a software error or if running a test server
    my $send_to_browser = $error->{status} != 500
                          || $ENV{NINKASI_TEST_SERVER_ROOT};

    # else (or if missing) replace message/title with something innocuous
    if ( !$send_to_browser || !$error->{message} ) {
        $error->{message} = $error_message{ $error->{status} };
        delete $template_input->{is_backtrace};
    }
    if ( !$send_to_browser || !$error->{title} ) {
        $error->{title} = $error_title{ $error->{status} };
    }

    $environment->transmit_header( 'html', -status => $error->{status} );
    $template_object->process( 'error.tt', {
        %$template_input,
        %$error
    } );

    croak $environment->path_info(), ': ', $error->{message};
}

sub render {
    my ($class) = @_;

    # determine whether we're a CGI or a command line utility
    my $environment_class = exists $ENV{REQUEST_METHOD} ? 'Ninkasi::CGI'
                                                        : 'Ninkasi::CommandLine'
                                                        ;
    eval "require $environment_class";
    die if $@;
    my $environment = $environment_class->new();
    my $argument = $environment->get_arguments();
    my ( $program_name, $positional, $option )
        = @$argument{ qw/program_name positional option/ };

    my @authorized_pages = ();
    my $template_object = Ninkasi::Template->new();
    my %template_input;

    eval {

        # escape to test backtrace
        if ( $program_name eq 'die' ) {

            # hack for testing what errors look like in production
            if ( exists $option->{to_browser} && !$option->{to_browser} ) {
                delete $ENV{NINKASI_TEST_SERVER_ROOT};
            }

            # throw backtrace
            confess;
        }

        # only allow appropriate modules
        die { status => 404 } if !exists $Page{$program_name};

        # load module
        my $module = join '::', __PACKAGE__,
                                join '', map { ucfirst } split '_',
                                                               $program_name;
        untaint $module;
        eval "require $module";
        die { status => 500, message => $@ } if $@;
        die { status => 500, message => "$module: can't transform" }
            if !$module->can('transform');

        # pass page names to appear in navbar & access level to template
        %template_input = (
            constraint_name       => \%Ninkasi::Constraint::NAME,
            escape_quotes         => sub { \&Ninkasi::CSV::escape_quotes },
            format                => $option->{format},
            page                  => $program_name,
            rank_name             => \%Ninkasi::Judge::NAME,
            remove_trailing_comma => sub {
                \&Ninkasi::CSV::remove_trailing_comma;
            },
        );

        # do the actual work, getting back data to pass to template
        my $transform_results = $module->transform( {
            %$option,
            -positional => $positional,
        } );

        %template_input = ( %template_input, %$transform_results );
    };
    if ( my $error = $@ ) {

        # structured data was passed through the exception
        if ( ref $error ) {

            # if a status is provided, print an error page and die
            if ( exists $error->{status} ) {
                die_with_error_page $environment, $error, $template_object,
                                    \%template_input;
            }

            # else just pass along the error message and other fields
            @template_input{ 'error',   @error_variables }
                  = @$error{ 'message', @error_variables };
        }

        # a plain string was passed -- we don't know what happened, so die
        else {
            $template_input{is_backtrace} = 1;
            die_with_error_page $environment, { message => $error },
                                $template_object, \%template_input;
        }
    }

    # send HTTP header
    $environment->transmit_header( $option->{format} );

    # when PDFs are emitted, send the content directly
    if ( $option->{format} eq 'print' ) {
        print $template_input{content};
        return;
    }

    # else use Template::Toolkit
    my $template_name = join '', $program_name,
                                 ( @$positional ? '' : '_index' ),
                                 '.tt';
    $template_object->process( $template_name, \%template_input );

    return;
}

1;
__END__

=head1 NAME

Ninkasi - web application to automate volunteer registration for BCJP competitions

=head1 VERSION

This documentation refers to Ninkasi version 0.0.1.

=head1 SYNOPSIS



=head1 DESCRIPTION

Ninkasi is a web-based volunteer registration system for BJCP homebrew
and professional beer competitions.  The Ninkasi module currently also
builds the Brewers' Cup web site.

=head1 SUBROUTINES/METHODS



=head1 DIAGNOSTICS



=head1 CONFIGURATION



=head1 ENVIRONMENT



=head1 DEPENDENCIES



=head1 INCOMPATIBILITIES



=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.  Please report problems to
Andrew Korty <ajk@iu.edu>.  Patches are welcome.

=head1 AUTHOR

Andrew Korty <ajk@iu.edu>

=head1 LICENSE AND COPYRIGHT

This software is in the public domain.

=head1 EXAMPLES



=head1 FREQUENTLY ASKED QUESTIONS



=head1 COMMON USAGE MISTAKES



=head1 ACKNOWLEDGMENTS



=head1 SEE ALSO


