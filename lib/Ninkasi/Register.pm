package Ninkasi::Register;

use strict;
use warnings;

use Data::Dumper;
use Date::Format qw/time2str/;
use File::Spec;
use Ninkasi::Assignment;
use Ninkasi::CSV;
use Ninkasi::Category;
use Ninkasi::Config;
use Ninkasi::Constraint;
use Ninkasi::Judge;
use Ninkasi::Table;
use Taint::Util;

our @REQUIRED_FIELDS = qw/first_name last_name address city state zip
                          phone_evening phone_day email1 email2/;

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
        print LOG time2str( '%b %d %T ', time() ), $ENV{REMOTE_ADDR}, ': ',
                  join(':', map {
                                my $value = $column->{$_};
                                $value =~ s/:/%3a/g;
                                "$_=$value";
                            } sort keys %$column),
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

    if ($column->{email1} ne $column->{email2}) {
        push @error_messages, "Your e-mail addresses don't seem to match";
        @error_field{ qw/email1 email2/ } = (1, 1);
    }

    if (!$column->{session1} && !$column->{session2} && !$column->{session3}) {
        push @error_messages, "You don't seem to have committed to any flights";
        @error_field{ qw/session1 session2 session3/ } = (1, 1, 1);
    }

    die {
        field    => \%error_field   ,
        messages => \@error_messages,
    } if @error_messages;

    foreach my $column_value (values %$column) {
        $column_value =~ s/^\s+//;
        $column_value =~ s/\s+$//;
    }

    return $column;
}

sub mail_confirmation {
    my ($column) = @_;

    # build message from template
    my $template_object = Ninkasi::Template->new();
    my $message;
    $template_object->process(
        'confirmation.tt',
        {
            form  => $column,
            title => "Brewers' Cup Judge Volunteer Confirmation",
            type  => 'mail',
        },
        \$message,
    ) or warn $template_object->error();

    # send message
    _send_mail $message;

    return;
}

# store the data submitted by the judge form in the database
sub store {
    my ($column) = @_;

    # log the submission in a flat file for safekeeping
    log_request $column;

    # validate the input
    $column = validate $column;

    # create judge & constraint objects
    my $judge_table = Ninkasi::Judge->new();
    my $constraint_table = Ninkasi::Constraint->new();
    my $assignment_table = Ninkasi::Assignment->new();

    # get a database handle
    my $dbh = Ninkasi::Table->Database_Handle();

    # disable autocommit to perform this operation as one transaction
    $dbh->{AutoCommit} = 0;

    # create a judge row
    my $judge_id = $judge_table->add( {
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
            category => $category->{number},
            judge    => $judge_id,
            type     => $Ninkasi::Constraint::NUMBER{$type_name},
        });
    }

    # create a row for each session the judge is available
    while (my ($name, $value) = each %$column) {
        my ($session) = $name =~ /^session(\d+)$/ or next;
        $assignment_table->add( {
            flight  => $value ? 0 : -1,
            session => $session,
            judge   => $judge_id,
        } );
    }

    # commit this transaction & re-enable autocommit
    $dbh->commit();
    $dbh->{AutoCommit} = 1;

    return;
}

sub render_page {
    my ($class, $cgi_object) = @_;

    my $cgi_param = $cgi_object->Vars();

    my $template_name = 'judge_form.html';
    my %template_variable = (
        categories => \@Ninkasi::Category::CATEGORIES,
        form       => $cgi_param,
        ranks      => \@Ninkasi::Judge::RANKS,
    );
    if (%$cgi_param) {
        eval { store $cgi_param };
        if ($@) {
            if (ref $@) {
                $template_variable{user_errors} = $@->{messages};
                $template_variable{error_field} = $@->{field   };
            }
            else {
                my $error_message = $@;
                $template_variable{system_error} = $error_message;
                eval { alert_maintainer $error_message, $cgi_param };
                if ($@) {
                    warn $@;
                }
            }
        }
        else {
            $template_name = 'confirmation.tt';
            $template_variable{type} = 'html';

            my $config = Ninkasi::Config->new();
            # if ( !$config->testing() ) {
            eval { mail_confirmation $cgi_param };
            if ($@) {
                warn $@;
            }
            # }
        }
    }

    my $template_object = Ninkasi::Template->new();
    $template_object->process($template_name, \%template_variable)
        or warn $template_object->error();
}

1;
