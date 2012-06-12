#!/usr/bin/perl

use strict;

use utf8;

use Test::More tests => 2;
use Test::Deep;

use Autozoil::Languagetool;
use Autozoil::Sink::Store;
use Autozoil::AutoSuppressor;
use Autozoil::Sink::Chain;
use Autozoil::Sink::Store;
use Autozoil::Sink::LineAdder;

my $filename = 'Autozoil/Languagetool/word_repeat_at_section.tex';

my $chain_sink = Autozoil::Sink::Chain->new();
my $line_adder = Autozoil::Sink::LineAdder->new($filename);
my $auto_suppressor = Autozoil::AutoSuppressor->new($filename);
my $store_sink = Autozoil::Sink::Store->new();
$chain_sink->add_sink($line_adder);
$chain_sink->add_sink($auto_suppressor);
$chain_sink->add_sink($store_sink);

my $language_tool = Autozoil::Languagetool->new($chain_sink, 'pl');

$language_tool->process($filename);

ok($store_sink->is_ok());

cmp_deeply(
    [ $store_sink->get_all_mistakes() ],
    [ ]);

