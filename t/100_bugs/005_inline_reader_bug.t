#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use Test::Exception;



=pod

This was a bug, but it is fixed now. This
test makes sure it does not creep back in.

=cut

{
    package Foo;
    use Mouse;

    ::lives_ok {
        has 'bar' => (
            is      => 'ro',
            isa     => 'Int',
            lazy    => 1,
            default => 10,
        );
    } '... this didnt die';
}

