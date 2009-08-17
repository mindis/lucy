use strict;
use warnings;

package Boilerplater::Parser;
use base qw( Parse::RecDescent );

use Boilerplater::Parcel;
use Boilerplater::Type;
use Boilerplater::Type::Primitive;
use Boilerplater::Type::Integer;
use Carp;

our $grammar = <<'END_GRAMMAR';

parcel_definition:
    'parcel' class_name cnick(?) ';'
    { 
        my $parcel = Boilerplater::Parser->new_parcel( \%item );
        Boilerplater::Parser->set_parcel($parcel);
        $parcel;
    }

class_name:
    class_name_component ( "::" class_name_component )(s?)
    { join('::', $item[1], @{ $item[2] } ) }

class_name_component:
    /[A-Z]+[A-Z0-9]*[a-z]+[A-Za-z0-9]*(?!\w)/

cnick:
    'cnick'
    /([A-Z][A-Za-z0-9]+)(?!\w)/
    { $1 }

c_integer_type:
    type_qualifier(s?) c_integer_specifier
    { Boilerplater::Parser->new_integer_type(\%item) }

chy_integer_type:
    type_qualifier(s?) chy_integer_specifier
    { Boilerplater::Parser->new_integer_type(\%item) }

type_qualifier:
      'const' 

primitive_type_specifier:
      chy_integer_specifier
    | c_integer_specifier 
    { $item[1] }

chy_integer_specifier:
    /(?:chy_)?([iu](8|16|32|64)|bool)_t(?!\w)/

c_integer_specifier:
    /(?:char|int|short|long|size_t)(?!\w)/

END_GRAMMAR

sub new { return shift->SUPER::new($grammar) }

our $parcel = undef;
sub set_parcel { $parcel = $_[1] }

sub new_integer_type {
    my ( undef, $item ) = @_;
    my $specifier = $item->{c_integer_specifier}
        || $item->{chy_integer_specifier};
    my %args = ( specifier => $specifier );
    $args{$_} = 1 for @{ $item->{'type_qualifier(s?)'} };
    return Boilerplater::Type::Integer->new(%args);
}

sub new_parcel {
    my ( undef, $item ) = @_;
    Boilerplater::Parcel->singleton(
        name  => $item->{class_name},
        cnick => $item->{'cnick(?)'}[0],
    );
}

1;

__END__

__POD__

=head1 NAME

Boilerplater::Parser - Parse Boilerplater header files.

=head1 SYNOPSIS

     my $class_def = $parser->class($class_text);

=head1 DESCRIPTION

Boilerplater::Parser is a combined lexer/parser which parses .bp code.  It is
not at all strict, as it relies heavily on the C parser to pick up errors such
as misspelled type names.

=head1 COPYRIGHT AND LICENSE

    /**
     * Copyright 2009 The Apache Software Foundation
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *     http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
     * implied.  See the License for the specific language governing
     * permissions and limitations under the License.
     */

=cut

