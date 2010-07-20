package Ninkasi;

use 5.008008;
use strict;
use warnings;

use Carp;
use Getopt::Long;
use Ninkasi::CGI;
use Ninkasi::CommandLine;
use Ninkasi::Template;

our $VERSION = '0.01';

my %status_message = (
    403 => 'You are not authorized to access this portion of the site.',
    404 => "We couldn't find the page you requested.",
);

sub die_with_error_page {
    my ( $environment, $status, $message, $template_input ) = @_;

    $environment->transmit_header( 'html', -status => $status );
    $template_object->new()->process( 'error.tt', {
        %$template_input,
        message => $message,
    } );

    croak $message;
}

sub render {
    my ($class) = @_;

    my $environment
        = ( exists $ENV{REQUEST_METHOD} ? 'Ninkasi::CGI'
                                        : 'Ninkasi::CommandLine' )->new();
    @ARGV = $environment->get_arguments();

    my %option = ( format => 'html' );
    my $program_name = $ARGV[0];
    my $template_object = Ninkasi::Template->new();
    my $template_input;

    eval {

        # only allow appropriate modules
        die { status => 404 } if !exists $Transformer{$program_name};

        # load module
        my $module = join '::', __PACKAGE__, ucfirst $program_name;
        untaint $module;
        require $module;

        # parse arguments
        GetOptions \%option, $module->get_argument_schema();
        $option{-nonoption} = \@ARGV;

        # redirect if trailing slash is missing
        if ( !$#ARGV && ( my $url = $environment->url( -path_info => 1 ) )
             && $url !~ m{/$} ) {
            print $environment->redirect("$url/");
            exit;
        }

        # do the actual work, getting back data to pass to template
        $template_input = $module->transform(
            \%option,
            constraint_name => \%Ninkasi::Constraint::NAME,
            rank_name       => \%Ninkasi::Judge::NAME,
            type            => $format,
        );

    };
    if ( my $error = $@ ) {

        # structured data was passed through the exception
        if ( ref $error ) {

            # if not provided, guess the error message
            my $message = exists $error->{message} ? $error->{message}
                : $status_message{ $error->{status} };

            # if a status is provided, print an error page and die
            if ( exists $error->{status} ) {
                die_with_error_page $environment, $error->{status}, $message,
                                    $template_input;
            }

            # else just pass along the error message
            $template_input{error} = $message;
        }

        # a plain string was passed -- we don't know what happened, so die
        else {
            die_with_error_page $environment, 500, $error, $template_input;
        }
    }

    # render page
    $environment->transmit_header( $option{format} );
    $template_object->new()->process( "$program_name.tt", $template_input );
}

1;
__END__

=head1 NAME

Ninkasi - web application to automate judge registration for BCJP competitions

=head1 VERSION

This documentation refers to Ninkasi version 0.0.1.

=head1 SYNOPSIS



=head1 DESCRIPTION

Ninkasi is a web-based judge registration system for BJCP homebrew and
professional beer competitions.  The Ninkasi module currently also
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


