#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;



{
    package Foo;
    use Mouse;

    has 'foo' => (is => 'rw', isa => 'Int');

    sub DEMOLISH { }
}

{
    package Bar;
    use Mouse;

    extends qw(Foo);
    has 'bar' => (is => 'rw', isa => 'Int');

    sub DEMOLISH { }
}

lives_ok {
    Bar->new();
} 'Bar->new()';

lives_ok {
    Bar->meta->make_immutable;
} 'Bar->meta->make_immutable';

is( Bar->meta->get_method('DESTROY')->package_name, 'Bar',
    'Bar has a DESTROY method in the Bar class (not inherited)' );

lives_ok {
    Foo->meta->make_immutable;
} 'Foo->meta->make_immutable';

is( Foo->meta->get_method('DESTROY')->package_name, 'Foo',
    'Foo has a DESTROY method in the Bar class (not inherited)' );
