#line 1

package Carp::Always;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.09';

use Carp qw(verbose); # makes carp() cluck and croak() confess

sub _warn {
  if ($_[-1] =~ /\n$/s) {
    my $arg = pop @_;
    $arg =~ s/ at .*? line .*?\n$//s;
    push @_, $arg;
  }
  warn &Carp::longmess;
}

sub _die {
  if ($_[-1] =~ /\n$/s) {
    my $arg = pop @_;
    $arg =~ s/ at .*? line .*?\n$//s;
    push @_, $arg;
  }
  die &Carp::longmess;
}

my %OLD_SIG;

BEGIN {
  @OLD_SIG{qw(__DIE__ __WARN__)} = @SIG{qw(__DIE__ __WARN__)};
  $SIG{__DIE__} = \&_die;
  $SIG{__WARN__} = \&_warn;
}

END {
  @SIG{qw(__DIE__ __WARN__)} = @OLD_SIG{qw(__DIE__ __WARN__)};
}

1;
__END__

#line 162
