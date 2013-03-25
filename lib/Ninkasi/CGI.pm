package Ninkasi::CGI;

use strict;
use warnings;

use base 'CGI::Simple';

sub get_arguments {
    my ($self) = @_;

    # get path info & remove empty element (before first /)
    my @positional = split '/', $self->path_info();
    shift @positional;

    # shift off 'manage'
    my $manage;
    if ( $positional[0] eq 'manage' ) {
        shift @positional;
        $manage = 1;
    }

    my $program_name = $positional[0];
    shift @positional;

    # unpack query string
    my %option = map {
        my @values = $self->param($_);
        $_ => @values > 1 ? \@values : $values[0];
    } $self->param();
    $option{-number_of_options} = keys %option;
    $option{format} ||= 'html';

    # redirect if no arguments and no trailing slash
    if (!@positional) {
        my $url = $self->url( -path_info => 1 );
        if ( $url && $manage && $url !~ m{/$} ) {

            # all requests go through /cgi; remove that from URL
            $url =~ s{/cgi/}{/};

            my $query_string = $self->query_string();
            $query_string &&= "?$query_string";
            print $self->redirect("$url/$query_string");
            exit;
        }
    }

    return {
        program_name => $program_name,
        positional   => \@positional,
        option       => \%option,
    };
}

sub transmit_header {
    my $self   = shift;
    my $format = shift || 'html';

    # set content type based on format parameter
    my @content_type = (
        -type    => $format eq 'csv'    ? 'text/plain'
                  : $format eq 'print'  ? 'application/pdf'
                  :                       'text/html'
    );

    # transmit CGI header
    print $self->header( -charset => 'utf-8', @content_type, @_ );

    return;
}

1;
__END__

=head1 NAME

Ninkasi::CGI - CGI::Simple(3) subclass for Ninkasi

=head1 SYNOPSIS

    # render a web page displaying all assignments
    Ninkasi::Assignment->render_page( Ninkasi::CGI->new() );

=head1 DESCRIPTION

Ninkasi::CGI is a subclass of L<CGI::Simple(3)> whose C<new()> method
also prints a CGI header specifying a charset of UTF-8.

=head1 SUBROUTINES/METHODS

All methods not listed below are inherited from L<CGI::Simple(3)>.

=over 4

=item new($class, @header_attributes)

The C<new()> method is a constructor method that does the following:

=over 4

=item 1.

Construct a new L<CGI::Simple(3)> object.

=item 2.

Print an HTTP header, defaulting to a charset of UTF-8.  The charset
may be overridden and other HTTP header fields may be specified in
C<@header_attributes>.

=item 3.

Return the L<CGI::Simple(3)> object, blessed into C<Ninkasi::CGI>.

=back

=head1 CONFIGURATION

No L<Ninkasi::Config(3)> variables are used by this module.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.  Please report problems to
Andrew Korty <andrew@korty.name>.  Patches are welcome.

=head1 AUTHOR

Andrew Korty <andrew@korty.name>

=head1 LICENSE AND COPYRIGHT

This software is in the public domain.

=head1 SEE ALSO

L<CGI::Simple(3)>
