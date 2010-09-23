package Ninkasi::MailingList;

use strict;
use warnings;

use base 'Ninkasi::Table';

my $table_name = 'mailing_list';
__PACKAGE__->Table_Name($table_name);
__PACKAGE__->Column_Names( [ qw/email/ ] );
__PACKAGE__->Schema(<<EOF);
CREATE TABLE "$table_name" (
    email TEXT UNIQUE
)
EOF

sub transform {
    my ( $class, $argument ) = @_;

    # fetch e-mail addresses from database
    my ( $mailing_list_handle, $mailing_list_row ) = $class->new()->bind_hash( {
            columns => ['email'],
            order   => 'email',
        } );

    # render page
    return {
        fetch_email => sub { $mailing_list_handle->fetch()
                             && $mailing_list_row },
    };
}

1;
