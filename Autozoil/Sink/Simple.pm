package Autozoil::Sink::Simple;

use strict;

sub new {
    my ($class, $args) = @_;

    my $source_file_prefix = '';

    if (exists $args->{'source_file_prefix'}) {
        $source_file_prefix = $args->{'source_file_prefix'};
    }

    my $self = { 'source_file_prefix' => $source_file_prefix } ;

    return bless $self, $class;
}


sub add_mistake {
    my ($self, $mistake) = @_;

    return if $mistake->{'suppressed'} || $mistake->{'unwanted'};

    print join(" *** ",
               $mistake->{'type'}.'-'.$mistake->{'label'},
               $self->clean_filename($mistake->{'filename'}) . ' ' . $mistake->{'line_number'},
               $mistake->{'frag'},
               $mistake->{'original_line'},
               $mistake->{'comment'},
               $mistake->{'correction'}),"\n\n";
}

sub finish {
}

sub clean_filename {
    my ($self, $filename) = @_;

    my $source_file_prefix = $self->{'source_file_prefix'} || '';

    $filename =~ s{^(.*)/}{};

    return $source_file_prefix . $filename;
}

1;
