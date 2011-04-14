#line 1
package Test::Exception::LessClever;
use strict;
use warnings;

use base 'Exporter';
use Test::Builder;
use Carp qw/carp/;

#{{{ POD

#line 52

#}}}

our @EXPORT_OK = qw/live_or_die/;
our @EXPORT = qw/lives_ok dies_ok throws_ok lives_and/;
our @CARP_NOT = ( __PACKAGE__ );
our $TB = Test::Builder->new;
our $VERSION = "0.006";

#line 77

sub live_or_die {
    my ( $code ) = @_;
    my $return = eval { $code->(); 'did not die' } || "died";
    my $msg = $@;

    if ( $return eq 'did not die' ) {
        return ( 1, $return ) if wantarray;
        return 1;
    }
    else {
        return 0 unless wantarray;

        if ( !$msg ) {
            carp "code died as expected, however the error is masked. This"
               . " can occur when an object's DESTROY() method calls eval";
        }

        return ( 0, $msg );
    }
}

#line 104

sub lives_ok(&;$) {
    my ( $code, $name ) = @_;
    my $ok = live_or_die( $code );
    $TB->ok( $ok, $name );
    return $ok;
}

#line 117

sub dies_ok(&;$) {
    my ( $code, $name ) = @_;
    my $ok = live_or_die( $code );
    $TB->ok( !$ok, $name );
    return !$ok;
}

#line 132

sub throws_ok(&$;$) {
    my ( $code, $reg, $name ) = @_;
    my ( $ok, $msg ) = live_or_die( $code );
    my ( $pkg, $file, $number ) = caller;

    # If we lived
    if ( $ok ) {
        $TB->diag( "Test did not die as expected at $file line $number." );
        return $TB->ok( !$ok, $name );
    }

    my $match = $msg =~ $reg ? 1 : 0;
    $TB->ok( $match, $name );

    $TB->diag( "$file line $number:\n  Wanted: $reg\n  Got: $msg" )
        unless( $match );

    return $match;
}

#line 160

sub lives_and(&;$) {
    my ( $code, $name ) = @_;
    my ( $ok, $msg )= live_or_die( $code );
    my ( $pkg, $file, $number ) = caller;
    chomp( $msg );
    $msg =~ s/\n/ /g;
    $TB->diag( "Test unexpectedly died: '$msg' at $file line $number." ) unless $ok;
    $TB->ok( $ok, $name ) if !$ok;
    return $ok;
}

1;

__END__

