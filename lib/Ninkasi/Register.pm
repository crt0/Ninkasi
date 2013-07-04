package Ninkasi::Register;

use strict;
use warnings;

use Data::Dumper;
use Date::Format qw/time2str/;
use Email::Address;
use File::Spec;
use Ninkasi::Assignment;
use Ninkasi::CSV;
use Ninkasi::Category;
use Ninkasi::Config;
use Ninkasi::Constraint;
use Ninkasi::Judge;
use Ninkasi::Table;
use Ninkasi::Volunteer;
use Taint::Util;

our @REQUIRED_FIELDS = qw/first_name last_name address city state zip
                          phone_evening phone_day email1 email2/;

sub create_rfc2822_address {
    my ($column) = @_;

    my $address = Email::Address->new( join( ' ', @$column{ qw/first_name
                                                               last_name/ } ),
                                       => $column->{email1} );

    return $address->format();
}

sub _send_mail {
    my ($message) = @_;

    $ENV{PATH} = '/usr/sbin';
    my $sendmail = '/usr/sbin/sendmail';
    if (-l $sendmail || -x $sendmail) {
        open SENDMAIL, "| $sendmail -t -oi"
            or die "error executing $sendmail: $!";
        print SENDMAIL $message
            or die "error printing via pipe to $sendmail: $!";
        close SENDMAIL
            or die "error when closing pipe to $sendmail: $!";

        return;
    }

    die 'could not find sendmail';

    return;
}

sub alert_maintainer {
    my ($error_message, $column) = @_;

    # get maintainer address
    my $config = Ninkasi::Config->new();
    my $maintainer_address = $config->maintainer_address();

    # construct message
    my $abbreviated_error_message = substr $error_message, 0, 70;
    my $mail_message = <<EOF;
From:    $maintainer_address
Subject: $abbreviated_error_message
To:      $maintainer_address

$error_message

EOF
    $mail_message .= Dumper $column;

    _send_mail $mail_message;

    return;
}

sub log_request {
    my ($column) = @_;

    my $config = Ninkasi::Config->new();
    my $log_file = $config->log_file();
    untaint $log_file;
    if (open LOG, ">>$log_file") {
        print LOG time2str( '%Y-%m-%d %T ', time() ), $ENV{REMOTE_ADDR}, ': ',
                  join(':', map {
                                my $value = $column->{$_};
                                $value =~ s/:/%3a/g;
                                "$_=$value";
                            } sort grep { !/^-/ && !/format|submit/ }
                                        keys %$column),
                  "\n";
        close LOG;
    }
    else {
        warn "$log_file: $!";
    }
}


sub validate {
    my ($column) = @_;

    my @error_messages = ();
    my %error_field    = ();

    my @empty_fields = grep { !$column->{$_} } @REQUIRED_FIELDS;
    if (@empty_fields) {
        my $plural = @empty_fields > 1 ? 's' : '';
        push @error_messages, join ' ', 'Looks like you left',
                                        scalar @empty_fields,
                                        "field$plural blank";
        @error_field{ @empty_fields } = (1) x @empty_fields;
    }

    # judges must have a valid BJCP id or be a pro
    if ( $column->{submit} eq 'Register to Judge'
         && $column->{bjcp_id} !~ /^[a-z]\d{4}$/i && !$column->{pro_brewer} ) {
        push @error_messages, 'You must have a valid BJCP id or be a '
                              . 'professional brewer to judge';
        @error_field{ qw/bjcp_id pro/ } = ( 1, 1 );
    }

    if ($column->{email1} ne $column->{email2}) {
        push @error_messages, "Your e-mail addresses don't seem to match";
        @error_field{ qw/email1 email2/ } = (1, 1);
    }

    if (!$column->{session1} && !$column->{session2} && !$column->{session3}) {
        push @error_messages, "You don't seem to have committed to any flights";
        @error_field{ qw/session1 session2 session3/ } = (1, 1, 1);
    }

    die {
        field   => \%error_field   ,
        message => \@error_messages,
    } if @error_messages;

    foreach my $column_value (values %$column) {
        $column_value =~ s/^\s+//;
        $column_value =~ s/\s+$//;
    }

    return $column;
}

sub mail_from_template {
    my ($argument) = @_;

    my $template   = $argument->{template  };
    my $form       = $argument->{form      };
    my $to_address = $argument->{to_address};
    my $title      = $argument->{title     };

    # build message from template
    my $template_object = Ninkasi::Template->new();
    my $config = Ninkasi::Config->new();
    my $message;
    $template_object->process(
        "$template.tt",
        {
            date1      => $config->date1(),
            date2      => $config->date2(),
            form       => $form,
            format     => 'mail',
            title      => $title,
            to_address => $to_address,
        },
        \$message,
    ) or warn $template_object->error();

    # send message
    _send_mail $message;

    return;
}

# store the data submitted by the volunteer form in the database
sub store {
    my ($column) = @_;

    # log the submission in a flat file for safekeeping
    log_request $column;

    # validate the input
    $column = validate $column;

    # create volunteer & constraint objects
    my $volunteer_class = $column->{role} eq 'steward' ? 'Ninkasi::Steward'
                                                       : 'Ninkasi::Judge';
    eval "require $volunteer_class";
    die if $@;
    my $volunteer_table = $volunteer_class->new();
    my $constraint_table = Ninkasi::Constraint->new();
    my $assignment_table = Ninkasi::Assignment->new();

    # get a database handle
    my $dbh = Ninkasi::Table->Database_Handle();

    # disable autocommit to perform this operation as one transaction
    $dbh->begin_work();
    eval {
        # create a volunteer row
        my $volunteer_id = $volunteer_table->add( {
            %$column,
            email => $column->{email1},
            when_created => time(),
        } );

        # walk through the categories and create a row for each constraint
        foreach my $category (@Ninkasi::Category::CATEGORIES) {

            # skip if no constraint was specified
            next if !exists $column->{ $category->{field_name} };

            # skip if we don't know the constraint type
            my $type_name = $column->{ $category->{field_name} };
            next if !exists $Ninkasi::Constraint::NUMBER{$type_name};

            # create a row for the constraint
            $constraint_table->add({
                category  => $category->{number},
                type      => $Ninkasi::Constraint::NUMBER{$type_name},
                volunteer => $volunteer_id,
            });
        }

        # create a row for each session the volunteer is available
        while (my ($name, $value) = each %$column) {
            my ($session) = $name =~ /^session(\d+)$/ or next;
            $assignment_table->add( {
                flight    => $value ? 0 : -1,
                session   => $session,
                volunteer => $volunteer_id,
            } );
        }
    };

    # on error, rollback, re-enable autocommit, & propagate the error
    if ($@) {
        $dbh->rollback();
        die $@;
    }

    # on success, commit this transaction & re-enable autocommit
    else {
        $dbh->commit();
    }

    return;
}

sub closed_disabled {
    my $role = ucfirst shift || 'Volunteer';
    my ( $month, $year ) = (localtime)[4 .. 5];
    $year += 1900;
    my ( $status, $when ) = $month < 6
                            ? ( 'not yet opened', 'soon' )
                            : ( 'closed'        , 'next year' )
                            ;
    return {
        message => <<EOF,
$role registration has $status for $year.  Please check back $when
to register!
EOF
        status  => 403,
        title   => 'Brewers&#8217; Cup Registration Closed',
    };
}

sub down_disabled {
    return {
        message => <<EOF,
The volunteer registration system is temporarily unavailable.  Please
try back in a few minutes.
EOF
        status  => 503,
        title   => 'Brewers&#8217; Cup Registration Down',
    };
}

sub transform {
    my ( $class, $argument ) = @_;

    # if app is disabled, display error card and exit
    my $config = Ninkasi::Config->new();
    my $disabled_value = $config->disabled();
    my @disabled_variables = ();
    if ($disabled_value) {
        no strict 'refs';
        my $disabled_func = $disabled_value . '_disabled';
        if ( defined &$disabled_func ) {
            die $disabled_func->();
        } else {
            @disabled_variables = ( disabled => $disabled_value );
        }
    }
    my @template_defaults = (
        categories => \@Ninkasi::Category::CATEGORIES,
        form       => $argument,
        ranks      => \@Ninkasi::Judge::RANKS,
        @disabled_variables
    );

    if ( $argument->{-number_of_options} ) {

        # determine role
        ( $argument->{role} = lc $argument->{submit} ) =~ s/register to //;
        if ( $disabled_value && $argument->{role} eq $disabled_value ) {
            die closed_disabled $argument->{role};
        }

        # store volunteer data
        eval { store $argument };
        if ( my $error = $@ ) {
            die ref $error ? { %$error, @template_defaults } : $error;
        }

        # mail confirmation & coordinator notifications unless testing
        if ( !$config->test_server_root() ) {
            my $coordinator_address = $config->get( $argument->{role} . '_coordinator' );
            eval {
                mail_from_template {
                    form       => $argument,
                    template   => 'confirmation',
                    title      => "Brewers' Cup Volunteer Confirmation",
                    to_address => create_rfc2822_address($argument),
                };
                mail_from_template {
                    form       => $argument,
                    template   => 'notification',
                    title      => join( ' ', "New $argument->{role}:",
                                             $argument->{first_name},
                                             $argument->{last_name} ),
                    to_address => Email::Address
                                  ->new(undef, $coordinator_address)->format(),
                };
            };
            if ($@) {
                warn $@;
            }
        }

        return {
            date1 => $config->date1(),
            date2 => $config->date2(),
            form  => $argument,
        };
    }

    return { @template_defaults };
}

1;
__END__

=head1 NAME

Ninkasi::Register - template logic for Ninkasi volunteer registration

=head1 SYNOPSIS

  use Ninkasi::Register;
  
  # transform user interface input into template input (really only
  # called by Ninkasi(3))
  $transform_results = Ninkasi::Register->transform( {
      \%options,
      -positional => \%positional_parameters,
  } );
  Ninkasi::Template->new()->process( register => $transform_results);

=head1 DESCRIPTION

Ninkasi::Register provides the logic for generating a web form to
register volunteers (judges and stewards); validate, process, and
store the results of the form; logs the request; and e-mail a
confirmation message to the volunteer.

This module defines a C<transform()> method to be called by
L<Ninkasi(3)>; see the latter for documentation on this method.

The methods of this module are not called directly by programs but by
C<Ninkasi-E<gt>render()>.

=head1 SUBROUTINES/METHODS

Ninkasi::Register is a subclass of L<Ninkasi::Table(3)>.

=head1 DIAGNOSTICS

If this module encounters an error while rendering a template,
C<Ninkasi::Template-E<gt>error()> is called to generate a warning message
that is printed on C<STDERR>.

=head1 CONFIGURATION

The following L<Ninkasi::Config(3)> variables are used by this module:

=over 4

=item date1

the date of the first judging session

=item date2

the date of the second judging session

=item disabled

when defined, disable registration, the value being the name of the
template to display instead of the registration form

=item log_file

file where registration data is logged

=item test_server_root

whether the module is being tested, in which case no confirmations
will be e-mailed

=back

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.  Please report problems to
Andrew Korty <andrew@korty.name>.  Patches are welcome.

=head1 AUTHOR

Andrew Korty <andrew@korty.name>

=head1 LICENSE AND COPYRIGHT

This software is in the public domain.

=head1 SEE ALSO

L<Ninkasi(3)>, L<Ninkasi::Config(3)>, L<Ninkasi::Table(3)>,
L<Ninkasi::Template(3)>
