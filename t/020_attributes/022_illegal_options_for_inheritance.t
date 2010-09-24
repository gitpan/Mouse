#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

{
    package Foo;
    use Mouse;

    has foo => (
        is => 'ro',
    );

    has bar => (
        clearer => 'clear_bar',
    );
}

{
    package Foo::Sub;
    use Mouse;

    extends 'Foo';

    ::lives_ok { has '+foo' => (is => 'rw') } "can override is";
    ::throws_ok { has '+foo' => (reader => 'bar') } qr/illegal/, "can't override reader";
    ::lives_ok { has '+foo' => (clearer => 'baz') }  "can override unspecified things";

    ::throws_ok { has '+bar' => (clearer => 'quux') }  qr/illegal/, "can't override clearer";
    ::lives_ok { has '+bar' => (predicate => 'has_bar') }  "can override unspecified things";
}

{
    package Bar::Meta::Attribute;
    use Mouse::Role;

    has my_illegal_option => (is => 'ro');

    around illegal_options_for_inheritance => sub {
        return (shift->(@_), 'my_illegal_option');
    };
}

{
    package Bar;
    use Mouse;

    ::lives_ok {
        has bar => (
            traits            => ['Bar::Meta::Attribute'],
            my_illegal_option => 'FOO',
            is                => 'bare',
        );
    } "can use illegal options";

    has baz => (
        traits => ['Bar::Meta::Attribute'],
        is     => 'bare',
    );
}

{
    package Bar::Sub;
    use Mouse;

    extends 'Bar';

    ::throws_ok { has '+bar' => (my_illegal_option => 'BAR') }
                qr/illegal/,
                "can't override illegal attribute";
    ::lives_ok { has '+baz' => (my_illegal_option => 'BAR') }
               "can add illegal option if superclass doesn't set it";
}

my $bar_attr = Bar->meta->get_attribute('bar');
ok((grep { $_ eq 'my_illegal_option' } $bar_attr->illegal_options_for_inheritance) > 0, '... added my_illegal_option as illegal option for inheritance');

done_testing;
