package Ninkasi::Assignment;

use strict;
use warnings;

use base 'Ninkasi::Table';

use Ninkasi::Category;
use Ninkasi::Constraint;
use Ninkasi::Judge;
use Ninkasi::Template;

__PACKAGE__->Table_Name('assignment');
__PACKAGE__->Column_Names(qw/category flight judge/);
__PACKAGE__->Create_Sql(<<'EOF');
CREATE TABLE assignment (
    category    INTEGER,
    flight      INTEGER,
    judge       INTEGER
)
EOF

# return a list of assignments for a specified judge
sub fetch {
    my ($judge_id, $suppress_hyperlinks) = @_;

    # fetch assignments for specified judge
    my $assignment = Ninkasi::Assignment->new();
    my ($sth, $result) = $assignment->bind_hash( {
        bind_values => [$judge_id],
        columns     => [qw/category flight/],
        where       => 'judge = ?',
    } );

    # walk the rows, building a list ordered by flight
    my @assignment_list = () x 4;
    while ( $sth->fetch() ) {
        my $category = $result->{category};
        my $column_value;

        # treat special category values -1 and 0
        if ($category == -1) {
            $column_value = 'N/A';
        }
        elsif ($category == 0) {
            $column_value = '';
        }

        # hyperlink if requested
        elsif ($suppress_hyperlinks) {
            $column_value = $category;
        }
        else {
            $column_value
                = qq{<a href="../assignment/$category">$category</a>};
        }

        $assignment_list[ $result->{flight} ] = $column_value;
    }

    # return 'N/A' for missing rows
    return [map { defined $_ ? $_ : 'N/A' } @assignment_list];
}

sub select_assigned_judges {
    my ($category) = @_;

    my @judge_columns = qw/judge.rowid first_name last_name rank
                           competitions_judged pro_brewer/;

    my $entry = $Ninkasi::Constraint::NUMBER{entry};

    my $judge = Ninkasi::Judge->new();
    my ($sth, $result) = $judge->bind_hash( {
        bind_values => [$category->{number}],
        columns     => \@judge_columns,
        join        => ['Ninkasi::Assignment', 'Ninkasi::Constraint'],
        order       => 'type DESC, rank DESC, competitions_judged DESC',
        where       => join(' ', 'judge.rowid IN (SELECT judge',
                                                 'FROM assignment',
                                                 'WHERE category = ?)'),
    } );
    $sth->bind_col(1, \$result->{rowid});

    return sub { $sth->fetch() && $result };
}

sub select_unassigned_judges {
    my ($category) = @_;

    my @judge_columns      = qw/judge.rowid first_name last_name rank
                                competitions_judged pro_brewer/;
    my @constraint_columns = qw/category type/;

    my $entry = $Ninkasi::Constraint::NUMBER{entry};

    my $where_clause = <<EOF;
judge.rowid = 'constraint'.judge
AND 'constraint'.category = ?
AND type != $entry
AND judge.rowid IN (SELECT DISTINCT judge FROM assignment WHERE category = 0)
EOF

    my $judge = Ninkasi::Judge->new();
    my ($sth, $result) = $judge->bind_hash( {
        bind_values => [$category->{number}],
        columns     => [@judge_columns, @constraint_columns],
        join        => 'Ninkasi::Constraint',
        order       => 'type DESC, rank DESC, competitions_judged DESC',
        where       => $where_clause,
    } );
    $sth->bind_col(1, \$result->{rowid});

    return sub { $sth->fetch() && $result };
}

sub render_page {
    my ($self, $cgi_object) = @_;

    # format paramter determines content type
    my $format = $cgi_object->param('format') || 'html';
    print $cgi_object->header($format eq 'html' ? 'text/html' : 'text/plain');

    # parse path_info to get category number
    my $category_number = ( split '/', $cgi_object->path_info(), 3 )[1];

    # render header
    my $category = $Ninkasi::Category::CATEGORIES[$category_number];
    my $template_object = Ninkasi::Template->new();

    # process the template, passing it a function to fetch judge data
    $template_object->process( 'assignment.tt', {
        assigned_judges_func   => sub { select_assigned_judges $category },
        category               => $category,
        constraint_name        => \%Ninkasi::Constraint::NAME,
        escape_quotes          => sub { \&escape_quotes },
        fetch_constraint       => \&Ninkasi::Constraint::fetch,
        rank_name              => \%Ninkasi::Judge::NAME,
        remove_trailing_comma  => sub { \&remove_trailing_comma },
        type                   => $format,
        unassigned_judges_func => sub { select_unassigned_judges $category },
    } ) or warn $template_object->error();

    return;
}

1;
