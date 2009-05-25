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
