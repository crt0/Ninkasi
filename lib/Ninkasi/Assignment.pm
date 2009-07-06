package Ninkasi::Assignment;

use strict;
use warnings;

use base 'Ninkasi::Table';

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
    print $cgi_object->header($format eq 'html' ? 'text/html' : 'text/plain');

    # process input
    if ( my $assign   = $cgi_object->param('assign'  ) ) {
        update_assignment [ $assign   ], $flight_number;
    }
    if ( my $unassign = $cgi_object->param('unassign') ) {
        update_assignment [ $unassign ], 0;
    }

    # escape HTML but not for CSV output
    my $escape_html = sub { $format eq 'csv' ? sub { shift } : 'html_entity' };

    # process the template, passing it a function to fetch judge data
    $template_object->process( 'assignment.tt', {
        assigned_judges_func   => sub { select_assigned_judges $flight },
        constraint_name        => \%Ninkasi::Constraint::NAME,
        escape_html            => $escape_html,
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
