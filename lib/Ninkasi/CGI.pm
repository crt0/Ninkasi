package Ninkasi::CGI;

use strict;
use warnings;

use CGI ();
use Ninkasi::Config;

sub new {
    my $cgi_object = CGI->new();

    # transmit CGI header
    print $cgi_object->header();

    # if app is disabled, display error card and exit
    my $config = Ninkasi::Config->new();
    if ( $config->disabled() ) {
        my $template_object = Ninkasi::Template->new();
        $template_object->process('disabled.html') or warn $template_object->error();
        exit;
    }

    return $cgi_object;
}

1;
