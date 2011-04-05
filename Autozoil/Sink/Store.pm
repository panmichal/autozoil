package Autozoil::Sink::Store;

use strict;

sub new {
    my ($class) = @_;

    my $self = {
        'mistakes' => []
    } ;

    return bless $self, $class;
}

sub add_mistake {
    my ($self, $mistake) = @_;

    push @{$self->{'mistakes'}}, $mistake;
}

sub get_all_mistakes {
    my ($self) = @_;

    return @{$self->{'mistakes'}};
}

sub is_ok {
    my ($self) = @_;

    return $#{$self->{'mistakes'}} == -1;
}

1;