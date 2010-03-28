package Ninkasi::Judge;

use strict;
use warnings;

use base 'Ninkasi::Table';

use Ninkasi::Assignment;
use Ninkasi::CSV;
use Ninkasi::Category;
use Ninkasi::Constraint;
use Ninkasi::Template;

__PACKAGE__->Table_Name('judge');
__PACKAGE__->Column_Names(qw/first_name last_name address city state zip
                             phone_evening phone_day email rank bjcp_id
                             competitions_judged pro_brewer when_created/);
__PACKAGE__->Schema(<<'EOF');
CREATE TABLE judge (
    first_name          TEXT,
    last_name           TEXT,
    address             TEXT,
    city                TEXT,
    state               TEXT,
    zip                 TEXT,
    phone_evening       TEXT,
    phone_day           TEXT,
    email               TEXT,
    rank                INTEGER,
    bjcp_id             TEXT,
    competitions_judged INTEGER,
    pro_brewer          INTEGER DEFAULT 0,
    when_created        INTEGER
)
EOF

our @RANKS = (
    {
        description => 'Novice -- little or no judging experience',
        name        => 'Novice',
        number      => 10,
    },
    {
        description => 'Experienced but not in the BJCP',
        name        => 'Experienced',
        number      => 20,
    },
    {
        description => 'BCJP Apprentice',
        name        => 'Apprentice',
        number      => 30,
    },
    {
        description => 'BJCP Recognized',
        name        => 'Recognized',
        number      => 40,
    },
    {
        description => 'BJCP Certified',
        name        => 'Certified',
        number      => 50,
    },
    {
        description => 'BJCP National',
        name        => 'National',
        number      => 60,
    },
    {
        description => 'BJCP Master',
        name        => 'Master',
        number      => 70,
    },
    {
        description => 'BJCP Grand Master',
        name        => 'Grand Master',
        number      => 80,
    },
);

our (%NAME, %NUMBER);
foreach my $rank (@RANKS) {
    $NAME  { $rank->{number} } = $rank->{name  };
    $NUMBER{ $rank->{name  } } = $rank->{number};
}

# display big table of all judges
sub render_all_judges {
    my ($cgi_object, $format) = @_;

    # columns to display
    my @judge_columns = qw/rowid first_name last_name rank competitions_judged
                           pro_brewer/;

    # select whole table & order by last name
    my $judge = Ninkasi::Judge->new();
    my ($sth, $result) = $judge->bind_hash( {
        columns  => \@judge_columns,
        order_by => 'last_name',
    } );

    # initialize queue for updates we'll find when rendering page
    my @update_queue = ();

    # process the template, passing it a function to fetch judge data
    my $template_object = Ninkasi::Template->new();
    $template_object->process( 'view_judges.tt', {
        cgi                   => scalar $cgi_object->Vars(),
        escape_quotes         => sub { \&Ninkasi::CSV::escape_quotes },
        fetch_judge           => sub {
            return $sth->fetch() && {
                %$result,
                fetch_assignments
                    => sub { Ninkasi::Assignment::fetch $result->{rowid} },
                fetch_flights
                    => sub { Ninkasi::Flight::fetch $result->{rowid} },
            };
        },
        rank_name             => \%Ninkasi::Judge::NAME,
        remove_trailing_comma => sub { \&Ninkasi::CSV::remove_trailing_comma },
        title                 => 'Registered Judges',
        type                  => $format,
    } ) or warn $template_object->error();
    $sth->finish();

    return;
}

sub render_judge {
    my ($cgi_object, $format, $judge_id) = @_;

    # show all judges if no id is specified
    return render_all_judges $cgi_object, $format if !$judge_id;

    # columns to display
    my @judge_columns = qw/rowid first_name last_name address city state zip
                           phone_evening phone_day email rank bjcp_id
                           competitions_judged pro_brewer when_created/;

    # fetch the judge object from the database
    my $judge = Ninkasi::Judge->new();
    my ($sth, $result) = $judge->bind_hash( {
        bind_values => [$judge_id],
        columns     => \@judge_columns,
        limit       => 1,
        where       => 'rowid = ?',
    } );
    $sth->fetch();

    # process the template to display this judge's information
    my $template_object = Ninkasi::Template->new();
    $template_object->process( 'view_judge.html', {
        judge     => $result,
        rank_name => \%Ninkasi::Judge::NAME,
        title     => join( ' ', @$result{qw/first_name last_name/} ),
    } ) or warn $template_object->error();

    # ignore remaining rows
    $sth->finish();

    return;
}

sub render_page {
    my ($class, $cgi_object) = @_;

    # parse path_info to get object id
    my ($id) = ( split '/', $cgi_object->path_info(), 3 )[1];

    # redirect if trailing slash is missing
    my $url = $cgi_object->url(-path_info => 1);
    if (!$id && $url !~ m{/$}) {
        print $cgi_object->redirect("$url/");
        exit;
    }

    # format paramter determines content type
    my $format = $cgi_object->param('format') || 'html';
    $cgi_object->transmit_header();

    if ( $format eq 'roster' ) {
        &Ninkasi::Assignment::print_roster;
        return;
    }

    # build & display selected view
    render_judge $cgi_object, $format, $id;
}

1;
