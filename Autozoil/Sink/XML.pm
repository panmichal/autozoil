package Autozoil::Sink::XML;

use strict;
use XML::Writer;

sub new {
    my ($class) = @_;

    my $self = { } ;

    my $writer = XML::Writer->new('DATA_INDENT' => ' ' x 4, 'DATA_MODE' => 1, 'ENCODING' => 'utf-8');

    $writer->xmlDecl();
    $writer->startTag('results', 'version' => '2');
    $writer->emptyTag('autozoil', 'version' => '0.1');
    $writer->startTag('errors');

    $self->{'writer'} = $writer;

    return bless $self, $class;
}


sub add_mistake {
    my ($self, $mistake) = @_;

    return if $mistake->{'suppressed'} || $mistake->{'unwanted'};

    my $writer = $self->{'writer'};

    $writer->startTag(
        'error',
        'id' => $mistake->{'type'}.'-'.$mistake->{'label'},
        'severity' => $mistake->{'type'},
        'correction' => $mistake->{'comment'},
        'msg' => $mistake->{'frag'});

    $writer->emptyTag(
        'location',
        'file' => clean_filename($mistake->{'filename'}),
        'line' => $mistake->{'line_number'});

    $writer->endTag();
}

sub finish {
    my ($self) = @_;

    my $writer = $self->{'writer'};

    $writer->endTag();
    $writer->endTag();
    $writer->end();
}

sub clean_filename {
    my ($filename) = @_;

    $filename =~ s{^(.*)/}{};

    return $filename;
}

1;
