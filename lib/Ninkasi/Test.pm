package Ninkasi::Test;

use Fatal qw/open close/;
use Mouse;

has mech => ( is => 'ro', isa => 'Test::WWW::Mechanize' );

sub dump_page {
    my $self = shift;

    open my $dump_handle, '>page.html';
    print {$dump_handle} $self->mech()->content();
    close $dump_handle;
}

__PACKAGE__->meta->make_immutable();

1;
