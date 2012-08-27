package Ninkasi::CSV;

sub escape_quotes {
    my ($text) = @_;
    $text =~ s/"/""/g;
    return $text;
}

sub remove_trailing_comma {
    my ($text) = @_;
    $text =~ s/,$//;
    return $text;
}

1;

__END__

=head1 NAME

Ninkasi::CSV - filter functions for outputting comma-separated values

=head1 SYNOPSIS

  $escaped_text = escape_quotes $unescaped_text;

  # bad example in Perl because you could just use join()
  $stringified_list = remove_trailing_comma map { "$_," } @list;

=head1 DESCRIPTION

Ninkasi::CSV offers filter functions for CSV processing in
L<Template Toolkit|Template(3)> templates.

=head1 SUBROUTINES/METHODS

=over 4

=item $output = escape_quotes($input)

The C<escape_quotes()> function escapes any double quote characters
(C<">) in C<$input> and returns the result.  Escaping is done by
prefixing each double quote character with another double quote
character, as is the CSV convention.

=item $output = remove_trailing_comma($input)

The C<remove_trailing_comma()> function removes the last character of
C<$input> if it is a comma character (C<,>).  This function is useful
in template loops that aggregate values into a string.

=back

=head1 CONFIGURATION

No L<Ninkasi::Config(3)> variables are used by this module.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.  Please report problems to
Andrew Korty <andrew@korty.name>.  Patches are welcome.

=head1 AUTHOR

Andrew Korty <andrew@korty.name>

=head1 LICENSE AND COPYRIGHT

This software is in the public domain.

=head1 EXAMPLES

The examples below assume references to the C<escape_quotes()> and
C<remove_trailing_comma()> methods have been passed to the template as
template variables of corresponding names.

=over 4

=item *

Escape quotes in template variables and send to output.

  "[% column1 | $escape_quotes %]","[% column2 | $escape_quotes %]"

=item *

Aggregate values by joining with commas, then remove the trailing
comma and send to output.

  [% BLOCK row -%]
    [% FOREACH column IN [column1, column2, ...] -%]
       "[% column1 | $escape_quotes %]",
    [%- END %]
  [% END -%]
  
  [% row | $remove_trailing_comma %]

=back

=head1 SEE ALSO

L<Ninkasi(3)>, L<Template(3)>
