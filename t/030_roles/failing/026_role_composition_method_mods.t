#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

use Mouse::Meta::Role::Application::RoleSummation;
use Mouse::Meta::Role::Composite;

{
    package Role::Foo;
    use Mouse::Role;

    before foo => sub { 'Role::Foo::foo' };
    around foo => sub { 'Role::Foo::foo' };
    after  foo => sub { 'Role::Foo::foo' };
    around baz => sub { [ 'Role::Foo', @{shift->(@_)} ] };

    package Role::Bar;
    use Mouse::Role;

    before bar => sub { 'Role::Bar::bar' };
    around bar => sub { 'Role::Bar::bar' };
    after  bar => sub { 'Role::Bar::bar' };

    package Role::Baz;
    use Mouse::Role;

    with 'Role::Foo';
    around baz => sub { [ 'Role::Baz', @{shift->(@_)} ] };

}

{
  package Class::FooBar;
  use Mouse;

  with 'Role::Baz';
  sub foo { 'placeholder' }
  sub baz { ['Class::FooBar'] }
}

#test modifier call order
{
    is_deeply(
        Class::FooBar->baz,
        ['Role::Baz','Role::Foo','Class::FooBar']
    );
}

# test simple overrides
{
    my $c = Mouse::Meta::Role::Composite->new(
        roles => [
            Role::Foo->meta,
            Role::Bar->meta,
        ]
    );
    isa_ok($c, 'Mouse::Meta::Role::Composite');

    is($c->name, 'Role::Foo|Role::Bar', '... got the composite role name');

    lives_ok {
        Mouse::Meta::Role::Application::RoleSummation->new->apply($c);
    } '... this succeeds as expected';

    is_deeply(
        [ sort $c->get_method_modifier_list('before') ],
        [ 'bar', 'foo' ],
        '... got the right list of methods'
    );

    is_deeply(
        [ sort $c->get_method_modifier_list('after') ],
        [ 'bar', 'foo' ],
        '... got the right list of methods'
    );

    is_deeply(
        [ sort $c->get_method_modifier_list('around') ],
        [ 'bar', 'baz', 'foo' ],
        '... got the right list of methods'
    );
}
