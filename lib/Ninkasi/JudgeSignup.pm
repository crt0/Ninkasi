package Ninkasi::JudgeSignup;

use strict;
use warnings;

use Data::Dumper;
use Date::Format qw/time2str/;
use File::Spec;
use LWP::UserAgent;
use Ninkasi::Config;
use Ninkasi::Constraint;
use Ninkasi::Judge;
use Ninkasi::Table;
use Smart::Comments;
use Taint::Util;

my @category_names = (
    'none',
    'Light Lager',
    'Pilsner',
    'European Amber Lager',
    'Dark Lager',
    'Bock',
    'Light Hybrid Beer',
    'Amber Hybrid Beer',
    'English Pale Ale',
    'Scottish and Irish Ale',
    'American Ale',
    'English Brown Ale',
    'Porter',
    'Stout',
    'India Pale Ale (IPA)',
    'German Wheat and Rye Beer',
    'Belgian and French Ale',
    'Sour Ale',
    'Belgian Strong Ale',
    'Strong Ale',
    'Fruit Beer',
    'Spice/Herb/Vegetable Beer',
    'Smoke-Flavored and Wood-Aged Beer',
    'Specialty Beer',
    'Unhopped Beer',
);

our @CATEGORIES = ();
foreach my $number (1..$#category_names) {
    push @CATEGORIES, {
        field_name => sprintf('category%02d', $number),
        name       => $category_names[$number],
        number     => $number,
    };
}

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

    if (!$column->{flight1} && !$column->{flight2} && !$column->{flight3}) {
        push @error_messages, "You don't seem to have committed to any flights";
        @error_field{ qw/flight1 flight2 flight3/ } = (1, 1, 1);
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
            title => 'Brewers Cup Judge Volunteer Confirmation',
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
    foreach my $category (@CATEGORIES) {

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

    # commit this transaction & re-enable autocommit
    $dbh->commit();
    $dbh->{AutoCommit} = 1;

    return;
}

1;
