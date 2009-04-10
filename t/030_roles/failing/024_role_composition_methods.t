#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 19;
use Test::Exception;

use Mouse::Meta::Role::Application::RoleSummation;
use Mouse::Meta::Role::Composite;

{
    package Role::Foo;
    use Mouse::Role;
    
    sub foo { 'Role::Foo::foo' }    
    
    package Role::Bar;
    use Mouse::Role;

    sub bar { 'Role::Bar::bar' }
    
    package Role::FooConflict;
    use Mouse::Role;    
    
    sub foo { 'Role::FooConflict::foo' }    
    
    package Role::BarConflict;
    use Mouse::Role;
    
    sub bar { 'Role::BarConflict::bar' }
    
    package Role::AnotherFooConflict;
    use Mouse::Role;    
    with 'Role::FooConflict';

    sub baz { 'Role::AnotherFooConflict::baz' }
}

# test simple attributes
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
        [ sort $c->get_method_list ],
        [ 'bar', 'foo' ],
        '... got the right list of methods'
    );
}

# test simple conflict
{
    my $c = Mouse::Meta::Role::Composite->new(
        roles => [
            Role::Foo->meta,
            Role::FooConflict->meta,
        ]
    );
    isa_ok($c, 'Mouse::Meta::Role::Composite');

    is($c->name, 'Role::Foo|Role::FooConflict', '... got the composite role name');    
    
    lives_ok {
        Mouse::Meta::Role::Application::RoleSummation->new->apply($c);
    } '... this succeeds as expected';    
    
    is_deeply(
        [ sort $c->get_method_list ],
        [],
        '... got the right list of methods'
    );    
    
    is_deeply(
        [ sort $c->get_required_method_list ],
        [ 'foo' ],
        '... got the right list of required methods'
    );    
}

# test complex conflict
{
    my $c = Mouse::Meta::Role::Composite->new(
        roles => [
            Role::Foo->meta,
            Role::Bar->meta,            
            Role::FooConflict->meta,
            Role::BarConflict->meta,            
        ]
    );
    isa_ok($c, 'Mouse::Meta::Role::Composite');

    is($c->name, 'Role::Foo|Role::Bar|Role::FooConflict|Role::BarConflict', '... got the composite role name');    

    lives_ok {
        Mouse::Meta::Role::Application::RoleSummation->new->apply($c);
    } '... this succeeds as expected';

    is_deeply(
        [ sort $c->get_method_list ],
        [],
        '... got the right list of methods'
    );    
    
    is_deeply(
        [ sort $c->get_required_method_list ],
        [ 'bar', 'foo' ],
        '... got the right list of required methods'
    );    
}

# test simple conflict
{
    my $c = Mouse::Meta::Role::Composite->new(
        roles => [
            Role::Foo->meta,
            Role::AnotherFooConflict->meta,
        ]
    );
    isa_ok($c, 'Mouse::Meta::Role::Composite');

    is($c->name, 'Role::Foo|Role::AnotherFooConflict', '... got the composite role name');    
    
    lives_ok {
        Mouse::Meta::Role::Application::RoleSummation->new->apply($c);
    } '... this succeeds as expected';    
    
    is_deeply(
        [ sort $c->get_method_list ],
        [ 'baz' ],
        '... got the right list of methods'
    );    
    
    is_deeply(
        [ sort $c->get_required_method_list ],
        [ 'foo' ],
        '... got the right list of required methods'
    );    
}

