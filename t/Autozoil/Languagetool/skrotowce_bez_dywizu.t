#!/usr/bin/perl

use strict;

use utf8;

use Test::More tests => 2;
use Test::Deep;

use Autozoil::Languagetool;
use Autozoil::Sink::Store;

my $store_sink = Autozoil::Sink::Store->new();
my $checker = Autozoil::Languagetool->new($store_sink, 'pl');

$checker->process('Autozoil/Languagetool/skrotowce_bez_dywizu.tex');

ok(!$store_sink->is_ok());

cmp_deeply(
    [ $store_sink->get_all_mistakes() ],
    [
     {
         'type' => 'grammar',
         'line_number' => 6,
         'beg' => ignore(),
         'end' => ignore(),
         'comment' => ignore(),
         'frag' => re('SVNa'),
         'label' => 'SKROTOWCE_BEZ_DYWIZU',
         'correction' => ignore()
     },
    ]);
