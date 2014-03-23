package Ninkasi;

use 5.008008;
use strict;
use warnings;

use Carp;
use Getopt::Long;
use Ninkasi::CGI;
use Ninkasi::CSV;
use Ninkasi::Config;
use Ninkasi::Template;
use Readonly;
use Taint::Util;

our $VERSION = '0.01';

my %Page;
@Page{ qw/assignment flight judge register roster steward volunteer/ } = ();

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

    # save real error message for log
    my $log_message = $error->{message};

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

    croak $environment->path_info(), ': ', $log_message || $error->{message};
}

sub render {
    my ($class) = @_;

    # turn on debug mode if requested
    my $debug_level = Ninkasi::Config->new()->dlevel();
    if ($debug_level) {
        $ENV{Smart_Comments} = join ':', map { '#' x ( $_ + 2 ) }
                                         ( 1 .. $debug_level );
    }

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

=head1 SYNOPSIS

    use Ninkasi;

    Ninkasi->render();

=head1 DESCRIPTION

Ninkasi is a web-based volunteer registration system for BJCP homebrew
and professional beer competitions.  The Ninkasi module currently also
builds the Brewers' Cup web site.

Ninkasi uses the L<Template Toolkit|http://template-toolkit.org/> to
pre-process content in the appropriate output format.  In most cases,
the format can be specified using the C<format> query parameter in the
URL for the resource being requested.  Currently, HTML (C<html>),
comma-separated value (C<csv>), and plain text e-mail (C<mail>)
formats are supported.

The Template Toolkit is also used to pre-process the static HTML pages
that make up the Brewers' Cup web site.  This pre-processing happens
when the C<./Build> script is run, and C<./Build install> installs the
static HTML files into the document root.

=head1 SUBROUTINES/METHODS

=over 4

=item render()

The C<render()> method uses information from the environment (such as
CGI or the command line) to determine which page to render and how,
and then do so.  The environment provides a program name, positional
arguments, and options.  See L<Ninkasi::CGI(3)> and
L<Ninkasi::CommandLine(3)> for examples of each.  The C<render()> method
uses the program name to determine a Ninkasi module to load and calls
the module's C<transform()> method with the positional arguments and
options.  The C<transform()> method returns template variables to pass
to a Template Toolkit template.

This method and the C<transform()> methods throw exceptions on error.
The exception object is a hash with the following fields:

  message   the error message
  status    a status code, similar to an HTTP response code

=item die_with_error_page($environment, $error, $template, $input)

Display an error page to the browser based on information from the
browser and emit an error message on the standard error.
C<$environment> is a L<Ninkasi::CGI(3)> or L<Ninkasi::CommandLine(3)>
object.  C<$error> is a hash with the following fields:

  message   the error message
  status    a status code, similar to an HTTP response code
  title     page title

C<$template> is the template object to use when rendering the error
(often the same template that was being processed when the error was
encountered -- for having the user correct errors in input).
C<$input> is a hash of Template Toolkit variables to pass to
C<$template>.

=back

=head1 DIAGNOSTICS

The C<render()> method throws an exception if

=over 4

=item *

the program name does not represent a class that can be loaded

=item *

the program name isn't present in a compile-time list of permitted program names

=item *

the module throws compile-time errors

=item *

the module doesn't have a C<transform()> method

=back

In addition, C<render()> passes along any errors thrown by the module
through the C<die_with_error_page()> method.

=head1 CONFIGURATION

See L<Ninkasi::Config(3)> for run-time configuration.

At build time, the document root and template directory may be set by
changing the C<%RELPATH> variable in the distribution's C<Build.PL>
file.

=head1 DEPENDENCIES

See the C<Build.PL> file bundled with the Ninkasi distribution for a
list of its software dependencies.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.  Please report problems to
Andrew Korty <andrew.korty@icloud.com>.  Patches are welcome.

=head1 AUTHOR

Andrew Korty <andrew.korty@icloud.com>

=head1 LICENSE AND COPYRIGHT

This software is in the public domain.

=head1 EXAMPLES

If the I</manage/volunteer/23?format=csv> URL were requested,
Ninkasi(3) would call

  Ninkasi::Volunteer->transform( { format => csv, -positional => [23] } )

=head1 SEE ALSO

L<Ninkasi::CGI(3)>, L<Ninkasi::CommandLine(3)>, L<Ninkasi::Config(3)>,
L<Template(3)>
