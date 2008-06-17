package Ninkasi::ApacheHandler;

use strict;
use warnings;

use Apache2::Const -compile => qw(OK);
use Apache2::RequestIO ();
use Apache2::RequestRec ();
use Carp;
use Ninkasi;
use Ninkasi::Config;
use Template;
use Template::Stash;

sub handler {
    my $r = shift;
    $r->content_type('text/html');

    # define vmethod to upcase first letter
    $Template::Stash::SCALAR_OPS->{ucfirst} = sub { ucfirst $_[0] };

    # set config and request as class data
    my $config = Ninkasi::Config::new 'Ninkasi::Config';
    Ninkasi->Config($config);
    Ninkasi->Request($r);

    # configure TT parser
    my $template_path = $config->get('template_path');
    my $tt = Template->new( {
        INCLUDE_PATH => $template_path,
        POST_PROCESS => $config->get('footer_template'),
        PRE_PROCESS  => $config->get('header_template'),
    } );

    # get template name from path info
    ( my $template_file = $r->path_info() ) =~ s{^/}{};
    $template_file ||= $config->get('index_template');
    my $output;

    # render requested page
    $tt->process($template_file, {requested_page => $template_file}, \$output)
        or croak $tt->error();
    $r->print($output);

    return Apache2::Const::OK;
}

1;
