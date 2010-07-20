package Ninkasi::CGI;

use strict;
use warnings;

use base 'CGI::Simple';

use Ninkasi::Config;

sub new {
    my $class = shift;

    my $self = $class->SUPER::new();

    # if app is disabled, display error card and exit
    my $config = Ninkasi::Config->new();
    my $disabled_template = $config->disabled();
    if ($disabled_template) {
        $self->transmit_header();
        my $template_object = Ninkasi::Template->new();
        $template_object->process("$disabled_template.html")
            or warn $template_object->error();
        exit;
    }

    return bless $self, $class;
}

sub get_arguments {
    my ($self) = @_;

    my @path_components = split '/', $self->path_info();

    return [ $path_components[0],
             ( map { "--$_=" . $self->param($_) } $self->param() ),
             @path_components[ 1..$#path_components ] ];
}

sub transmit_header {
    my $self   = shift;
    my $format = shift || 'html';

    # set content type based on format parameter
    my @content_type = (
        -type    => $format eq 'card'   ? 'application/pdf'
                  : $format eq 'csv'    ? 'text/plain'
                  : $format eq 'roster' ? 'application/pdf'
                  :                       'text/html'
    );

    # transmit CGI header
    print $self->header( -charset => 'utf-8', @content_type, @_ );

    return;
}

1;
__END__

=head1 NAME

Ninkasi::CGI - CGI(3) subclass for Ninkasi

=head1 SYNOPSIS

    # render a web page displaying all assignments
    Ninkasi::Assignment->render_page( Ninkasi::CGI->new() );

=head1 DESCRIPTION

Ninkasi::CGI is a subclass of CGI(3) whose I<new> method provides the
following additional features:

=over 4

=item *

prints a CGI header specifying a charset of UTF-8

=item *

allows Ninkasi to be disabled with a Ninkasi::Config(3) variable,
instead rendering a "disabled" template

=back

=head1 SUBROUTINES/METHODS

All methods not listed below are inherited from CGI(3).

=over 4

=item new $class, @header_attributes

The I<new> is a constructor method that does the following:

=over 4

=item 1.

Construct a new CGI(3) object.

=item 2.

Print an HTTP header, defaulting to a charset of UTF-8.  The charset
may be overridden and other HTTP header fields may be specified in
I<@header_attributes>.

=item 3.

If the I<disabled> configuration variable is set, render the template
named C<$disabled>I<_template.html> and exit.

=item 4.

Return the CGI(3) object, blessed into Ninkasi::CGI.

=back

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


