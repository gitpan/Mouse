#!/usr/bin/env perl
package Mouse;
use strict;
use warnings;
use base 'Exporter';

our $VERSION = '0.09';
use 5.006;

use Carp 'confess';
use Mouse::Util 'blessed';

use Mouse::Meta::Attribute;
use Mouse::Meta::Class;
use Mouse::Object;
use Mouse::TypeRegistry;

our @EXPORT = qw(extends has before after around blessed confess with);

sub extends { Mouse::Meta::Class->initialize(caller)->superclasses(@_) }

sub has {
    my $meta = Mouse::Meta::Class->initialize(caller);

    my $names = shift;
    $names = [$names] if !ref($names);

    for my $name (@$names) {
        if ($name =~ s/^\+//) {
            Mouse::Meta::Attribute->clone_parent($meta, $name, @_);
        }
        else {
            Mouse::Meta::Attribute->create($meta, $name, @_);
        }
    }
}

sub before {
    my $meta = Mouse::Meta::Class->initialize(caller);

    my $code = pop;

    for (@_) {
        $meta->add_before_method_modifier($_ => $code);
    }
}

sub after {
    my $meta = Mouse::Meta::Class->initialize(caller);

    my $code = pop;

    for (@_) {
        $meta->add_after_method_modifier($_ => $code);
    }
}

sub around {
    my $meta = Mouse::Meta::Class->initialize(caller);

    my $code = pop;

    for (@_) {
        $meta->add_around_method_modifier($_ => $code);
    }
}

sub with {
    my $meta = Mouse::Meta::Class->initialize(caller);

    my $role  = shift;

    confess "Mouse::Role only supports 'with' on individual roles at a time" if @_;

    Mouse::load_class($role);
    $role->meta->apply($meta);
}

sub import {
    strict->import;
    warnings->import;

    my $caller = caller;

    my $meta = Mouse::Meta::Class->initialize($caller);
    $meta->superclasses('Mouse::Object')
        unless $meta->superclasses;

    no strict 'refs';
    no warnings 'redefine';
    *{$caller.'::meta'} = sub { $meta };

    Mouse->export_to_level(1, @_);
}

sub unimport {
    my $caller = caller;

    no strict 'refs';
    for my $keyword (@EXPORT) {
        delete ${ $caller . '::' }{$keyword};
    }
}

sub load_class {
    my $class = shift;

    if (ref($class) || !defined($class) || !length($class)) {
        my $display = defined($class) ? $class : 'undef';
        confess "Invalid class name ($display)";
    }

    return 1 if is_class_loaded($class);

    (my $file = "$class.pm") =~ s{::}{/}g;

    eval { CORE::require($file) };
    confess "Could not load class ($class) because : $@" if $@;

    return 1;
}

sub is_class_loaded {
    my $class = shift;

    return 0 if ref($class) || !defined($class) || !length($class);

    # walk the symbol table tree to avoid autovififying
    # \*{${main::}{"Foo::"}} == \*main::Foo::

    my $pack = \*::;
    foreach my $part (split('::', $class)) {
        return 0 unless exists ${$$pack}{"${part}::"};
        $pack = \*{${$$pack}{"${part}::"}};
    }

    # check for $VERSION or @ISA
    return 1 if exists ${$$pack}{VERSION}
             && defined *{${$$pack}{VERSION}}{SCALAR};
    return 1 if exists ${$$pack}{ISA}
             && defined *{${$$pack}{ISA}}{ARRAY};

    # check for any method
    foreach ( keys %{$$pack} ) {
        next if substr($_, -2, 2) eq '::';
        return 1 if defined *{${$$pack}{$_}}{CODE};
    }

    # fail
    return 0;
}

1;

__END__

=head1 NAME

Mouse - Moose minus the antlers

=head1 SYNOPSIS

    package Point;
    use Mouse; # automatically turns on strict and warnings

    has 'x' => (is => 'rw', isa => 'Int');
    has 'y' => (is => 'rw', isa => 'Int');

    sub clear {
        my $self = shift;
        $self->x(0);
        $self->y(0);
    }

    package Point3D;
    use Mouse;

    extends 'Point';

    has 'z' => (is => 'rw', isa => 'Int');

    after 'clear' => sub {
        my $self = shift;
        $self->z(0);
    };

=head1 DESCRIPTION

L<Moose> is wonderful.

Unfortunately, it's a little slow. Though significant progress has been made
over the years, the compile time penalty is a non-starter for some
applications.

Mouse aims to alleviate this by providing a subset of Moose's
functionality, faster. In particular, L<Moose/has> is missing only a few
expert-level features.

We're also going as light on dependencies as possible. Most functions we use
from L<Scalar::Util> are copied into this dist. L<Scalar::Util> is required if
you'd like weak references; there's simply no way to do it from pure Perl.
L<Class::Method::Modifiers> is required if you want support for L</before>,
L</after>, and L</around>.

=head2 MOOSE COMPAT

Compatibility with Moose has been the utmost concern. Fewer than 1% of the
tests fail when run against Moose instead of Mouse. Mouse code coverage is also
over 96%. Even the error messages are taken from Moose. The Mouse code just
runs the test suite 4x faster.

The idea is that, if you need the extra power, you should be able to run
C<s/Mouse/Moose/g> on your codebase and have nothing break. To that end,
nothingmuch has written L<Squirrel> (part of this distribution) which will act
as Mouse unless Moose is loaded, in which case it will act as Moose.

Mouse also has the blessings of Moose's author, stevan.

=head2 MISSING FEATURES

=head3 Roles

We're working on fixing this one! stevan has suggested an implementation
strategy. Mouse currently ignores methods, so that needs to be fixed next.
Roles that consist entirely of attributes may be usable in this very version.

=head3 Complex types

User-defined type constraints and parameterized types may be implemented. Type
coercions probably not (patches welcome).

=head3 Bootstrapped meta world

Very handy for extensions to the MOP. Not pressing, but would be nice to have.

=head3 Modification of attribute metaclass

When you declare an attribute with L</has>, you get the inlined accessors
installed immediately. Modifying the attribute metaclass, even if possible,
does nothing.

=head3 Lots more..

MouseX?

=head1 KEYWORDS

=head2 meta -> Mouse::Meta::Class

Returns this class' metaclass instance.

=head2 extends superclasses

Sets this class' superclasses.

=head2 before (method|methods) => Code

Installs a "before" method modifier. See L<Moose/before> or
L<Class::Method::Modifiers/before>.

Use of this feature requires L<Class::Method::Modifiers>!

=head2 after (method|methods) => Code

Installs an "after" method modifier. See L<Moose/after> or
L<Class::Method::Modifiers/after>.

Use of this feature requires L<Class::Method::Modifiers>!

=head2 around (method|methods) => Code

Installs an "around" method modifier. See L<Moose/around> or
L<Class::Method::Modifiers/around>.

Use of this feature requires L<Class::Method::Modifiers>!

=head2 has (name|names) => parameters

Adds an attribute (or if passed an arrayref of names, multiple attributes) to
this class. Options:

=over 4

=item is => ro|rw

If specified, inlines a read-only/read-write accessor with the same name as
the attribute.

=item isa => TypeConstraint

Provides basic type checking in the constructor and accessor. Basic types such
as C<Int>, C<ArrayRef>, C<Defined> are supported. Any unknown type is taken to
be a class check (e.g. isa => 'DateTime' would accept only L<DateTime>
objects).

=item required => 0|1

Whether this attribute is required to have a value. If the attribute is lazy or
has a builder, then providing a value for the attribute in the constructor is
optional.

=item init_arg => Str

Allows you to use a different key name in the constructor.

=item default => Value | CodeRef

Sets the default value of the attribute. If the default is a coderef, it will
be invoked to get the default value. Due to quirks of Perl, any bare reference
is forbidden, you must wrap the reference in a coderef. Otherwise, all
instances will share the same reference.

=item lazy => 0|1

If specified, the default is calculated on demand instead of in the
constructor.

=item predicate => Str

Lets you specify a method name for installing a predicate method, which checks
that the attribute has a value. It will not invoke a lazy default or builder
method.

=item clearer => Str

Lets you specify a method name for installing a clearer method, which clears
the attribute's value from the instance. On the next read, lazy or builder will
be invoked.

=item handles => HashRef|ArrayRef

Lets you specify methods to delegate to the attribute. ArrayRef forwards the
given method names to method calls on the attribute. HashRef maps local method
names to remote method names called on the attribute. Other forms of
L</handles>, such as regular expression and coderef, are not yet supported.

=item weak_ref => 0|1

Lets you automatically weaken any reference stored in the attribute.

Use of this feature requires L<Scalar::Util>!

=item trigger => CodeRef

Any time the attribute's value is set (either through the accessor or the constructor), the trigger is called on it. The trigger receives as arguments the instance, the new value, and the attribute instance.

Mouse 0.05 supported more complex triggers, but this behavior is now removed.

=item builder => Str

Defines a method name to be called to provide the default value of the
attribute. C<< builder => 'build_foo' >> is mostly equivalent to
C<< default => sub { $_[0]->build_foo } >>.

=item auto_deref => 0|1

Allows you to automatically dereference ArrayRef and HashRef attributes in list
context. In scalar context, the reference is returned (NOT the list length or
bucket status). You must specify an appropriate type constraint to use
auto_deref.

=back

=head2 confess error -> BOOM

L<Carp/confess> for your convenience.

=head2 blessed value -> ClassName | undef

L<Scalar::Util/blessed> for your convenience.

=head1 MISC

=head2 import

Importing Mouse will default your class' superclass list to L<Mouse::Object>.
You may use L</extends> to replace the superclass list.

=head2 unimport

Please unimport Mouse (C<no Mouse>) so that if someone calls one of the
keywords (such as L</extends>) it will break loudly instead breaking subtly.

=head1 FUNCTIONS

=head2 load_class Class::Name

This will load a given C<Class::Name> (or die if it's not loadable).
This function can be used in place of tricks like
C<eval "use $module"> or using C<require>.

=head2 is_class_loaded Class::Name -> Bool

Returns whether this class is actually loaded or not. It uses a heuristic which
involves checking for the existence of C<$VERSION>, C<@ISA>, and any
locally-defined method.

=head1 AUTHOR

Shawn M Moore, C<< <sartak at gmail.com> >>

Yuval Kogman, C<< <nothingmuch at woobling.org> >>

with plenty of code borrowed from L<Class::MOP> and L<Moose>

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-mouse at rt.cpan.org>, or browse
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mouse>.

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Shawn M Moore.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

