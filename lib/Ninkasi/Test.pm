package Ninkasi::Test;

use Apache::TestConfig;
use Fatal qw/open close/;
use Mouse;
use Ninkasi::Table;
use Test::WWW::Mechanize;

BEGIN { Ninkasi::Table->initialize_database( { unlink => 1 } ) }

has mech     => ( is => 'ro', isa => 'Test::WWW::Mechanize' );
has url_base => ( is => 'ro', isa => 'Str'                  );

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    my $test_config = Apache::TestConfig->new();

    return $class->$orig(
        mech     => Test::WWW::Mechanize->new(),
        url_base => join ( '', $test_config->{vars}{scheme}, '://',
                               $test_config->hostport() ),
    );
};

sub dump_page {
    my $self = shift;

    open my $dump_handle, '>page.html';
    print {$dump_handle} $self->mech()->content();
    close $dump_handle;
}

__PACKAGE__->meta->make_immutable();

1;
