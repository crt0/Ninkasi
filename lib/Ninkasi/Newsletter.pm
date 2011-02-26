package Ninkasi::Newsletter;

use strict;
use warnings;

use Email::Address;
use Ninkasi::MailingList;

sub transform {
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
            eval { Ninkasi::MailingList->new()->add( { email => $email_1 } ) };

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
