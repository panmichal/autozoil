#!/usr/bin/perl

use strict;

BEGIN {
    push @INC, `pwd`;
}

binmode(STDOUT,':utf8');

use Autozoil::Spell;
use Autozoil::Chktex;
use Autozoil::Languagetool;
use Autozoil::LogAnalyser;
use Autozoil::Typo;
use Autozoil::AutoSuppressor;
use Autozoil::Suppressor;
use Autozoil::Sink::Simple;
use Autozoil::Sink::Chain;
use Autozoil::Sink::Store;
use Autozoil::Sink::LineAdder;
use Autozoil::Sink::XML;

use Getopt::Long;

my $locale;
my $format;
my $source_file_prefix = '';

GetOptions(
    'locale:s' => \$locale,
    'help' => \&help,
    'format:s' => \$format,
    'source-file-prefix:s' => \$source_file_prefix
) or die "wrong argument, type -h for help\n";

my $filename = $ARGV[0];

if (!defined($locale)) {
    $locale = 'pl_PL';
}

if (!defined($format)) {
    $format = 'txt';
}

my $output_sink;

my $sink_args = {'source_file_prefix' => $source_file_prefix};

if ($format eq 'txt') {
    $output_sink = Autozoil::Sink::Simple->new($sink_args);
} elsif ($format eq 'xml') {
    $output_sink = Autozoil::Sink::XML->new($sink_args);
} else {
    die "unknown format `$format`";
}

my $store_sink = Autozoil::Sink::Store->new();
my $chain_sink = Autozoil::Sink::Chain->new();
my $line_adder = Autozoil::Sink::LineAdder->new($filename);
my $auto_suppressor = Autozoil::AutoSuppressor->new($filename);
my $suppressor = Autozoil::Suppressor->new($filename);
$chain_sink->add_sink($line_adder);
$chain_sink->add_sink($auto_suppressor);
$chain_sink->add_sink($suppressor);
$chain_sink->add_sink($output_sink);
$chain_sink->add_sink($store_sink);

my $spell_dictionaries = $locale;
my $iso_dic_name = 'tmp-extra-pl-iso-8859-2';

if ($locale eq 'pl_PL') {
    $spell_dictionaries = "pl_PL,$iso_dic_name";
    prepare_iso_dic();
}
elsif ($locale eq 'en_GB') {
    $spell_dictionaries = "en_GB,extra-en";
}

my $lang;

if ($locale =~ /^([^_]+)_/) {
    $lang = $1;
} else {
    die "unexpected locale '$locale'"
}

my @checkers =
    (Autozoil::Spell->new($chain_sink, $spell_dictionaries),
     Autozoil::Chktex->new($chain_sink),
     Autozoil::Languagetool->new($chain_sink, $lang),
     Autozoil::Typo->new($chain_sink, $lang),
     Autozoil::LogAnalyser->new($chain_sink));

print STDERR "STARTING AUTOZOIL\n";

for my $checker (@checkers) {
    $checker->process($filename);
}

my $post_chain_sink = Autozoil::Sink::Chain->new();
$post_chain_sink->add_sink($line_adder);
$post_chain_sink->add_sink($output_sink);
$post_chain_sink->add_sink($store_sink);
$suppressor->postcheck($post_chain_sink);

$output_sink->finish();

if ($store_sink->is_ok()) {
    print STDERR "AUTOZOIL FOUND NO PROBLEMS, CONGRATS!\n";
    exit 0;
} else {
    print STDERR "AUTOZOIL FOUND ". $store_sink->get_number_of_problems()  ." PROBLEMS\n";
    exit 1;
}

sub prepare_iso_dic {
    `iconv -f UTF-8 -t ISO-8859-2 < extra-pl.dic > ${iso_dic_name}.dic`;
}

sub help {
    print STDERR <<'END_OF_HELP';
Autozoil is a comprehensive checker for texts written in (La)Tex,
mainly MSc theses and scientific papers.

Running:

    autozoil file.tex --locale pl_PL

Options:

    --help               prints this text
    --locale pl_PL|en_GB chooses locale
    --format txt|xml     error information format
    --source-file-prefix prefix added to source filenames
                         when reported
END_OF_HELP
    exit 2
}
