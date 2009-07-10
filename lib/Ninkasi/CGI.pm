package Ninkasi::CGI;

use strict;
use warnings;

use CGI ();
use Ninkasi::Config;

sub new {
    my $class = shift;

    my $cgi_object = CGI->new();

    # transmit CGI header
    print $cgi_object->header(-charset => 'utf-8', @_);

    # if app is disabled, display error card and exit
    my $config = Ninkasi::Config->new();
    my $disabled_template = $config->disabled();
    if ($disabled_template) {
        my $template_object = Ninkasi::Template->new();
        $template_object->process("$disabled_template.html")
            or warn $template_object->error();
        exit;
    }

    return $cgi_object;
}

1;
