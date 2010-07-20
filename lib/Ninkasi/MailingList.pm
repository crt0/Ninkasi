package Ninkasi::MailingList;

use strict;
use warnings;

use base 'Ninkasi::Table';

use Email::Address;
use Ninkasi::Template;

my $table_name = 'mailing_list';
__PACKAGE__->Table_Name($table_name);
__PACKAGE__->Column_Names( qw/email/ );
__PACKAGE__->Schema(<<EOF);
CREATE TABLE "$table_name" (
    email TEXT UNIQUE
)
EOF

sub render_management_page {
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

sub render_signup_page {
    my ( $class, $argument ) = @_;

    # create template object for output
    my %template_variable = ();

    if ( exists $argument->{email_1} ) {

        my $email_1 = $argument->{email_1};
        my $email_2 = $argument->{email_2};

        # make sure the address match
        if ( $email_1 ne $email_2 ) {
            $template_variable{user_error}
                = 'The e-mail addresses did not match.';
        }

        # validate address
        elsif ( !Email::Address->parse($email_1) ) {
            $template_variable{user_error}
                = "We don't recognize the format of your e-mail address.";
        }

        # insert into database
        else {
            eval { $self->add( { email => $email_1 } ) };

            # report database error (submitting an existing address is not one)
            if ( $@ && $@ !~ / is not unique/ ) {
                $template_variable{system_error} = $@;
            }

            # report success in template
            else {
                $template_variable{success} = 1;
            }
        }
    }

    return \%template_variable;
}

1;
