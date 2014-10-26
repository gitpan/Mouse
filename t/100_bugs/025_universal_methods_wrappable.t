use strict;
use warnings;

use Test::Exception;
use Test::More tests => 2;

{

    package FakeBar;
    use Mouse::Role;

    around isa => sub {
        my ( $orig, $self, $v ) = @_;
        return 1 if $v eq 'Bar';
        return $orig->( $self, $v );
    };

    package Foo;
    use Mouse;

    use Test::More; # for $TODO

    local $TODO = 'UNIVERSAL methods should be wrappable';

    ::lives_ok { with 'FakeBar' } 'applied role';

    my $foo = Foo->new;
    ::isa_ok $foo, 'Bar';
}
