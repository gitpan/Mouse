#!perl
use strict;
use warnings;
use constant HAS_THREADS => eval{ require threads };

use if !HAS_THREADS, 'Test::More', (skip_all => "This is a test for threads ($@)");
use Test::More;

{
    package MyTraits;
    use Mouse::Role;

    package MyClass;
    use Mouse;

    has foo => (
        is => 'rw',
        isa => 'Foo',
    );

    package Foo;
    use Mouse;

    has value => (
        is => 'rw',
        isa => 'Int',

        traits => [qw(MyTraits)],
    );
}

my $o = MyClass->new(foo => Foo->new(value => 42));
threads->create(sub{
    my $x = MyClass->new(foo => Foo->new(value => 1));
    is $x->foo->value, 1;

    $x->foo(Foo->new(value => 2));

    is $x->foo->value, 2;

    MyClass->meta->make_immutable();

    $x = MyClass->new(foo => Foo->new(value => 10));
    is $x->foo->value, 10;

    $x->foo(Foo->new(value => 20));

    is $x->foo->value, 20;
})->join();

is $o->foo->value, 42;

$o = MyClass->new(foo => Foo->new(value => 43));
is $o->foo->value, 43;

ok !$o->meta->is_immutable;

done_testing;
