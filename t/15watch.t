#!perl -w
use Test::More tests => 4;
use lib 't/lib';
use Test::IsEscapes qw( isq );
use Term::HiliteDiff;

my $d = Term::HiliteDiff->new;
isq( $d->watch('xxx xxx xxx'), "\e[sxxx xxx xxx", 'xxx xxx xxx' );
isq( $d->watch('xxx xxx AAA'), "\e[uxxx xxx \e[7mAAA\e[0m\e[K", 'xxx xxx AAA' );
isq( $d->watch('xxx BBB xxx'), "\e[uxxx \e[7mBBB\e[0m \e[7mxxx\e[0m\e[K", 'xxx BBB xxx' );
isq( $d->watch('CCC xxx xxx'), "\e[u\e[7mCCC\e[0m \e[7mxxx\e[0m xxx\e[K", 'CCC xxx xxx' );

# TODO: test for needing to add \n\e[K entries to clear previously
# printed but now empty lines

# TODO: test that last line ends with \e[K

# TODO: test that all lines run \e[K\n
