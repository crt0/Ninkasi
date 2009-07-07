package Ninkasi::Assignment;

use strict;
use warnings;

use base 'Ninkasi::Table';

use IPC::Open2 ();
use Ninkasi::Category;
use Ninkasi::Constraint;
use Ninkasi::Flight;
use Ninkasi::Judge;
use Ninkasi::Template;

__PACKAGE__->Table_Name('assignment');
__PACKAGE__->Column_Names(qw/flight judge session/);
__PACKAGE__->Create_Sql(<<'EOF');
CREATE TABLE assignment (
    flight  TEXT,
    judge   INTEGER,
    session INTEGER
)
EOF

# return a list of assignments for a specified judge
sub fetch {
    my ($judge_id) = @_;

    # fetch assignments for specified judge
    my $assignment = Ninkasi::Assignment->new();
    my ($sth, $result) = $assignment->bind_hash( {
        bind_values => [$judge_id],
        columns     => [qw/flight session/],
        where       => 'judge = ?',
    } );

    # walk the rows, building a list ordered by flight
    my @assignment_list = ('N/A') x 4;
    while ( $sth->fetch() ) {
        # treat category value 0 as unassigned
        $assignment_list[ $result->{session} ]
            = $result->{flight} ? $result->{flight} : '';
    }

    return \@assignment_list;
}

sub select_assigned_judges {
    my ($flight) = @_;

    my @judge_columns      = qw/judge.rowid first_name last_name rank
                                competitions_judged pro_brewer/;
    my @constraint_columns = qw/type/;

    my $judge = Ninkasi::Judge->new();
    my ($sth, $result) = $judge->bind_hash( {
        bind_values => [ @$flight{ qw/category number/ } ],
        columns     => [@judge_columns, @constraint_columns],
        join        => 'Ninkasi::Constraint',
        order       => 'type DESC, rank DESC, competitions_judged DESC',
        where       => join(' ', "judge.rowid = 'constraint'.judge",
                                 "AND 'constraint'.category = ?",
                                 'AND judge.rowid IN (SELECT DISTINCT judge',
                                                 'FROM assignment',
                                                 'WHERE flight = ?)'),
    } );
    $sth->bind_col(1, \$result->{rowid});

    return sub {
        return $sth->fetch() && {
            %$result,
            fetch_assignments => sub { fetch $result->{rowid} },
        };
    };
}

sub select_unassigned_judges {
    my ($flight) = @_;

    my @columns = qw/judge.rowid 'constraint'.category first_name last_name
                     rank competitions_judged pro_brewer type/;

    my $entry = $Ninkasi::Constraint::NUMBER{entry};

    my $where_clause = <<EOF;
judge.rowid = 'constraint'.judge
AND flight.number = ?
AND flight.category = 'constraint'.category
AND (type != $entry OR judge.pro_brewer != flight.pro)
AND judge.rowid IN (SELECT DISTINCT judge FROM assignment WHERE flight = 0)
AND judge.rowid NOT IN (SELECT DISTINCT judge FROM assignment WHERE flight = ?)
EOF

    my $judge = Ninkasi::Judge->new();
    my ($sth, $result) = $judge->bind_hash( {
        bind_values => [ ( $flight->{number} ) x 2 ],
        columns     => \@columns,
        join        => [ qw/Ninkasi::Constraint Ninkasi::Flight/ ],
        order       => 'type DESC, rank DESC, competitions_judged DESC',
        where       => $where_clause,
    } );
    $sth->bind_col( 1, \$result->{rowid   } );
    $sth->bind_col( 2, \$result->{category} );

    return sub {
        return $sth->fetch() && {
            %$result,
            fetch_assignments => sub { fetch $result->{rowid} },
        };
    };
}

sub serialize {
    my ($data) = @_;
    return join '_', map { join '-', $_, $data->{$_} } keys %$data;
}

sub deserialize {
    my ($string) = @_;

    my %data = ();
    foreach my $pair (split /_/, $string) {
        my ($name, $value) = split /-/, $pair;
        $data{$name} = $value;
    }

    return \%data;
}

sub update_assignment {
    my ($assignments, $flight_number) = @_;

    my $dbh = Ninkasi::Assignment->Database_Handle();
    my @columns = qw/judge session/;
    foreach my $assignment (@$assignments) {
        my $constraint = deserialize $assignment;
        my $sql = <<EOF;
UPDATE assignment SET flight = ? WHERE judge = ? AND session = ?
EOF
        $dbh->do($sql, {}, $flight_number, @$constraint{@columns});
    }
}

sub groff_to_pdf {
    my ($groff, @options) = @_;

    $ENV{PATH} = '/usr/bin';
    my ($groff_pid, $groff_reader, $groff_writer);
    eval {
        $groff_pid = IPC::Open2::open2 $groff_reader, $groff_writer,
                                       qw/groff -Tps/, @options;
    };
    if ($@) {
        if ($@ =~ /^open2/) {
            warn "open2: $!\n$@\n";
            return;
        }
        die;
    }

    print $groff_writer $groff;
    close $groff_writer;
    local $/;
    my $postscript = <$groff_reader>;
    close $groff_reader;
    waitpid $groff_pid, 0;

    my ($ps2pdf_pid, $ps2pdf_reader, $ps2pdf_writer);
    eval {
        $ps2pdf_pid = IPC::Open2::open2 $ps2pdf_reader, $ps2pdf_writer,
                                        qw/ps2pdf - -/;
    };
    if ($@) {
        if ($@ =~ /^open2/) {
            warn "open2: $!\n$@\n";
            return;
        }
        die;
    }

    print $ps2pdf_writer $postscript;
    close $ps2pdf_writer;
    print <$ps2pdf_reader>;
    close $ps2pdf_reader;
    waitpid $ps2pdf_pid, 0;

    return;
}

sub print_roster {

    # select whole judge table & order by last name
    my $judge_table = Ninkasi::Judge->new();
    my ( $judge_handle, $judge ) = $judge_table->bind_hash( {
        columns => [ qw/rowid first_name last_name/ ],
        order   => 'last_name',
    } );

    my $assignment_table = Ninkasi::Assignment->new();
    my @groff = ();
    for (;;) {

        my @rows = ();
        my $finished = 0;
        for (;;) {

            if ( !$judge_handle->fetch() ) {
                $finished = 1;
                last;
            }

            last if @rows > 38;

            my @columns = qw/flight session description number pro/;
            my ( $assignment_handle, $result )
                = $assignment_table->bind_hash( {
                    bind_values => [ $judge->{rowid} ],
                    columns     => \@columns,
                    join        => 'Ninkasi::Flight',
                    where       => 'assignment.flight = flight.number' .
                                   ' AND judge = ?',
                } );
            my @assignments = '' x 3;
            while ( $assignment_handle->fetch() ) {
                my $division = $result->{pro} ? 'pro' : 'hb';
                $assignments[ $result->{session} ] =
                    "$result->{number}: $result->{description} ($division)";
            }

            push @rows,
                join ';', "$judge->{last_name}, $judge->{first_name}",
                          map { defined $_ ? $_ : '' } @assignments[1..3];
        }

        # draw a horizonal line every three rows for legibility
        my $rows = '';
        my @triplets = ();
        while ( my @three = splice @rows, 0, 3 ) {
            push @triplets, join "\n", @three;
        }
        $rows = join "\n_\n", @triplets;

        push @groff, <<EOF;
.fam H
.sp 2
.TS
tab(;);
lb lb lb lb
l  l  l  l  .
Judge;Friday PM;Saturday AM; Saturday PM
_
$rows
.TE
EOF

        last if $finished;
    }

    groff_to_pdf join("\n.bp\n", @groff), qw/-t -P-l/;

    return;
}

sub print_table_card {
    my ($flight) = @_;

    my $division = $flight->{pro} ? 'Professional' : 'Homebrew';

    my $fetch_judge = select_assigned_judges $flight;
    my @judges = ();
    while ( my $judge = &$fetch_judge ) {
        push @judges, $judge;
    }
    my ($head_judge, $other_judges) = ('', '');
    if (@judges) {
        my @judge_strings = map { join ' ', @$_{ qw/first_name last_name/ } }
                                @judges;
        $head_judge = $judge_strings[0];
        $other_judges = join "\n", @judge_strings[1..$#judge_strings];
    }

    groff_to_pdf <<EOF;
.fam H
.ce 100
.ps 96
.vs 115
.sp
Table $flight->{number}
.ps 48
.vs 58
.sp
$flight->{description}
$division Division
.sp
.ps 32
.vs 38
.ft I
$head_judge
.ft
$other_judges
EOF

    return;
}

sub render_page {
    my ($self, $cgi_object) = @_;

    # create template object for output
    my $template_object = Ninkasi::Template->new();

    # parse path_info to get flight number and then flight info from db
    my $flight_number = ( split '/', $cgi_object->path_info(), 3 )[1];
    my $flight_table = Ninkasi::Flight->new();
    my ($sth, $flight) = $flight_table->bind_hash( {
        bind_values => [$flight_number],
        columns     => [qw/category description pro number/],
        where       => 'number = ?',
    } );

    if ( !$sth->fetch() ) {
        print $cgi_object->header(-status => '404 Not Found');
        $template_object->process( 'flight_404.html',
                                   {flight_number => $flight_number} )
            or warn $template_object->error();
        exit 404;
    }

    $sth->finish();

    # format parameter determines content type
    my $format = $cgi_object->param('format') || 'html';
    print $cgi_object->header( $format eq 'csv'  ? 'text/plain'
                             : $format eq 'card' ? 'application/pdf'
                             :                     'text/html'       );

    # process table card
    if ( $format eq 'card' ) {
        print_table_card $flight;
        return;
    }

    # process input
    if ( my @assign   = $cgi_object->param('assign'  ) ) {
        update_assignment \@assign  , $flight_number;
    }
    if ( my @unassign = $cgi_object->param('unassign') ) {
        update_assignment \@unassign, 0;
    }

    # process the template, passing it a function to fetch judge data
    $template_object->process( 'assignment.tt', {
        assigned_judges_func   => sub { select_assigned_judges $flight },
        constraint_name        => \%Ninkasi::Constraint::NAME,
        escape_quotes          => sub { \&escape_quotes },
        fetch_constraint       => \&Ninkasi::Constraint::fetch,
        flight                 => $flight,
        rank_name              => \%Ninkasi::Judge::NAME,
        remove_trailing_comma  => sub { \&remove_trailing_comma },
        type                   => $format,
        unassigned_judges_func => sub { select_unassigned_judges $flight },
    } ) or warn $template_object->error();

    return;
}

1;
