
package Autozoil::Languagetool;

use strict;

use XML::Simple;
use FileHandle;
use Data::Dumper;

my @unwanted_errors = split/\n/,<< 'END_OF_UNWANTED_ERRORS';
WHITESPACE_RULE
UPPERCASE_SENTENCE_START
COMMA_PARENTHESIS_WHITESPACE
LACZNIK_MYSLNIK
DOUBLE_PUNCTUATION
PL_GUILLEMET
END_OF_UNWANTED_ERRORS

my %unwanted_skrotowce_bez_dywizu = map { $_ => 1 } split/\n/,<<'END_OF_UNWANTED_SKROTOWCE_BEZ_DYWIZU';
PDFB-ox
SQL-ite
END_OF_UNWANTED_SKROTOWCE_BEZ_DYWIZU

sub new {
    my ($class, $sink, $language) = @_;

    my $self = {
        'sink' => $sink,
        'language' => $language,
        'extra_command' => '',
    };

    # detex leaves arguments of initial commands under Ubuntu
    my $good_detex = is_detex_good();

    if (!$good_detex) {
        $self->{'extra_command'} = q{| perl -ne 'if (/\\\\begin\\{document\\}/..1) { print; } else {print "\n";}'};
        print $self->{'extra_command'},"\n";
    }

    return bless $self, $class;
}

sub is_detex_good {
    my $result = qx{echo '\\usepackage[utf8]{inputenc}' | detex -l};

    return $result !~ /\S/;
}

sub process {
    my ($self, $filename) = @_;

    my $language = $self->{'language'};
    my $disable_option = join(',', @unwanted_errors);

    my $tmp_file = `mktemp`;
    chomp $tmp_file;
    $tmp_file .= '.txt';
    my $out_tmp_file = `mktemp`;
    chomp $out_tmp_file;
    my $two_backslashes_quoted = q{\\\\\\\\};
    my $two_spaces = q{  };

    my $extra_command = $self->{'extra_command'};

    # detex zamienia \\ na znak końca wiersza, co psuje zgodność
    # numeracji wierszy, musimy to naprawić
    `perl -pne 's{$two_backslashes_quoted}{$two_spaces}g; s{ -- }{ -  }g;' < "$filename" $extra_command | detex -l - > "$tmp_file"`;
    $self->check_if_document_class_in_oneline($filename);

    # languagetool output has to processed because of some bug in
    # languagetool
    `languagetool -c utf8 -l "$language" -d "$disable_option" --api "$tmp_file" | perl -ne 'BEGIN{print qq{<?xml version="1.0" encoding="UTF-8"?><matches>}}END{print qq{</matches>}} print if /^<error/' > "$out_tmp_file"`;

    my $ref = XMLin($out_tmp_file, 'ForceArray' => 1);

    if (ref $ref->{'error'}) {
        for my $error (@{$ref->{'error'}}) {
            $self->process_error($error);
        }
    }
}

sub check_if_document_class_in_oneline {
    my ($self, $filename) = @_;

    my $sink = $self->{'sink'};

    open my $fh, '<', $filename;
    binmode($fh, ':utf8');

    my $line_number = 1;

    PRECHECK_LOOP:
    while (my $line=<$fh>) {
        chomp $line;
        if ($line =~ m{^ \s* \\documentclass\[ }x) {
            if ($line =~ m{ ^ \s* \\documentclass\[ [^\]]* $ }x) {
                $sink->add_mistake({
                    'line_number' => $line_number,
                    'frag' => $line,
                    'type' => 'grammar',
                    'comment' =>
                        '\\documentclass[...] should be written in a single line in order for detex to work correctly',
                    'label' => 'DOCUMENTCLASS_NOT_IN_SINGLE_LINE'
                })
            }

            last PRECHECK_LOOP;
        }

        ++$line_number;
    }
}

sub process_error {
    my ($self, $error) = @_;

    return if
        $error->{'ruleId'} eq 'SKROTY_Z_KROPKA' && $error->{'msg'} =~ /'pl\.'/
        ||
        $error->{'ruleId'} eq 'BRAK_SPACJI' && $error->{'msg'} =~ /': '/
            && $error->{'context'} =~ m{http://}
        ||
        $error->{'ruleId'} eq 'SKROTOWCE_BEZ_DYWIZU'
            && exists $unwanted_skrotowce_bez_dywizu{$error->{'replacements'}};

    my $sink = $self->{'sink'};

    $sink->add_mistake({
        'line_number' => $error->{'fromy'} + 1,
        'frag' => $error->{'context'},
        'beg' => $error->{'fromx'},
        'end' => $error->{'tox'},
        'comment' => $error->{'msg'},
        'correction' => $error->{'replacements'} ,
        'type' => 'grammar',
        'label' => $error->{'ruleId'},
    });
}
