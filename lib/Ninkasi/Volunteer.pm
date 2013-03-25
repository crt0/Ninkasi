package Ninkasi::Volunteer;

use strict;
use warnings;

use base 'Ninkasi::Table';

use Ninkasi::Assignment;
use Ninkasi::CSV;
use Ninkasi::Category;
use Ninkasi::Template;

__PACKAGE__->Table_Name('volunteer');
__PACKAGE__->Column_Names( [ qw/first_name last_name address city state zip
                                phone_evening phone_day email rank bjcp_id
                                competitions_judged pro_brewer
                                when_created role/ ] );
__PACKAGE__->Schema(<<'EOF');
CREATE TABLE volunteer (
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
    when_created        INTEGER,
    role                TEXT
)
EOF

sub role { lcfirst ( ( split '::', ref $_[0] || $_[0] )[-1] ) }

sub add {
    my ( $self, $column ) = @_;

    $column->{role} = $self->role();

    return $self->SUPER::add($column);
}

# display big table of all volunteers
sub get_all {
    my ( $class, $argument ) = @_;

    # select whole table & order by last name
    my $volunteer_table = $class->new();
    my $quoted_role
        = $volunteer_table->Database_Handle->quote( $class->role() );
    my $where_clause;
    if ( $class ne __PACKAGE__ ) {
        $where_clause = "role = $quoted_role";
    }
    my ( $volunteer_handle, $volunteer_row ) = $volunteer_table->bind_hash( {
        columns  => [ qw/rowid first_name last_name rank competitions_judged
                         pro_brewer address city state zip phone_day
                         phone_evening email bjcp_id role/ ],
        order_by => 'last_name',
        where    => $where_clause,
    } );

    # build roster link, if any
    my $roster_credential = Ninkasi::Config->new()->get('roster');

    # return callback to fetch volunteer data and some helper functions
    return {
        argument => $argument,
        fetch_volunteer => sub {
            $volunteer_handle->fetch() && {
                %$volunteer_row,
                fetch_assignments => sub {
                    return Ninkasi::Assignment::fetch $volunteer_row->{rowid};
                },
                fetch_flights => sub {
                    return Ninkasi::Flight::fetch $volunteer_row->{rowid};
                },
            };
        },
        roster_credential => $roster_credential,
        title => "Registered ${quoted_role}s",
    };
}

sub transform {
    my ( $class, $argument ) = @_;

    my $volunteer_id = $argument->{-positional}[0];

    # print roster if requested
    return { content => Ninkasi::Assignment::print_roster( $class->role() ) }
           if $argument->{format} eq 'print';

    # show all volunteers if no id is specified
    if (!$volunteer_id) {
        return $class->get_all($argument);
    }

    # specialize where clause if a role is specified
    my $volunteer_table = $class->new();
    my $where_clause = 'rowid = ? AND role = '
                       . $volunteer_table->Database_Handle
                                         ->quote( $class->role() );

    # fetch the row for this volunteer from the database
    my ( $volunteer_handle, $volunteer_row ) = $volunteer_table->bind_hash( {
        bind_values => [$volunteer_id],
        columns     => [ qw/rowid first_name last_name address city state zip
                            phone_evening phone_day email rank bjcp_id
                            competitions_judged pro_brewer when_created/ ],
        limit       => 1,
        where       => $where_clause,
    } );
    $volunteer_handle->fetch();
    $volunteer_handle->finish();

    return {
        rank_name         => \%Ninkasi::Judge::NAME,
        volunteer_row     => $volunteer_row,
    };
}

1;
__END__

=head1 NAME

Ninkasi::Volunteer - Ninkasi class representing judges and stewards

=head1 SYNOPSIS

  use Ninkasi::Volunteer;

  # transform user interface input into template input (really only
  # called by Ninkasi(3))
  $transform_results = Ninkasi::Volunteer->transform( {
      \%options,
      -positional => \%positional_parameters,
  } );
  Ninkasi::Template->new()->process( volunteer => $transform_results);

  # look up a volunteer and display some of his/her attributes
  my $volunteer_table = Ninkasi::Volunteer->new();
  my ( $volunteer_handle, $volunteer_row ) = $volunteer_table->bind_hash( {
      bind_values => [$volunteer_id],
      columns     => [ qw/rowid first_name last_name address city state zip
                          phone_evening phone_day email rank bjcp_id
                          competitions_judged pro_brewer when_created/ ],
      limit       => 1,
      where       => $where_clause,
  } );
  print <<EOF;
Volunteer: $first_name $last_name
  Address: $address, $city, $state $zip
    Phone: $phone_day
   E-Mail: $email
EOF
  if ( $role = 'judge' ) {
      use Ninkasi::Judge;

      print <<EOF;
     Rank: $Ninkasi::Judge::NAME{$rank}
  BJCP ID: $bjcp_id
EOF
  }

=head1 DESCRIPTION

Ninkasi::Volunteer provides an interface to a database table of
competition volunteers (see L<Ninkasi::Judge(3)> and
L<Ninkasi::Steward(3)>) whose availability can be tracked, and in the
case of judges, who can be assigned to flights, for competition.

=head1 SUBROUTINES/METHODS

Ninkasi::Volunteer defines a C<transform()> method to be called by
L<Ninkasi(3)>; see the latter for documentation on this method.

This module is a subclass of L<Ninkasi::Table(3)>.

=head1 DIAGNOSTICS

If this module encounters an error while rendering a template,
C<Ninkasi::Template-E<gt>error()> is called to generate a warning message
that is printed on C<STDERR>.  If an error is encountered while
updating a flight, the database is rolled back.

=head1 CONFIGURATION

The C<roster> configuration variable is used to determine whether the
roster is enabled and its URL (see L<Ninkasi::Config(3)>).

=head1 BUGS AND LIMITATIONS

While L<Ninkasi::Judge(3)> and L<Ninkasi::Steward(3)> inherit from
this module, they doesn't act as subclasses in any useful way except
to inherit C<transform()>.

Please report problems to Andrew Korty <andrew@korty.name>.  Patches
are welcome.

=head1 AUTHOR

Andrew Korty <andrew@korty.name>

=head1 LICENSE AND COPYRIGHT

This software is in the public domain.

=head1 SEE ALSO

Ninkasi(3), Ninkasi::Config(3), Ninkasi::Judge(3),
Ninkasi::Steward(3), Ninkasi::Table(3)
