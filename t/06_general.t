# 06_general.t
#
# Test suite for Regexp::Assemble
# Check out the general functionality, now that all the subsystems have been exercised
#
# copyright (C) 2004-2005 David Landgren

use strict;
use Regexp::Assemble;

use Test::More tests => 30;

use constant NR_GOOD  => 45;
use constant NR_BAD   => 529;
use constant NR_ERROR => 0;

my $target;
my $ra = Regexp::Assemble->new->add( qw/foo bar rat/ );

for $target( qw/unfooled disembark vibration/ ) {
    ok( $target =~  /$ra/, "match ok $target" )
}

for $target( qw/unfooled disembark vibration/ ) {
    ok( $target !~ /^$ra/, "anchored match not ok $target" )
}

$ra->reset;

for $target( qw/unfooled disembark vibration/ ) {
    ok( $target !~  /$ra/, "fail after reset $target" )
}

$ra->add( qw/who what where why when/ );

for $target( qw/unfooled disembark vibration/ ) {
    ok( $target !~  /$ra/, "fail ok $target" )
}

for $target( qw/snowhouse somewhat nowhereness whyever nowhence/ ) {
    ok( $target =~  /$ra/, "new match ok $target" )
}

$ra->reset->mutable(1);

ok( 'nothing' !~ /$ra/, "match nothing after reset" );

$ra->add( '^foo\\d+' );

ok( 'foo12'  =~ /$ra/, "match 1 ok foo12" );
ok( 'nfoo12' !~ /$ra/, "match 1 nok nfoo12" );
ok( 'bar6'   !~ /$ra/, "match 1 nok bar6" );

$ra->add( 'bar\\d+' );

ok( 'foo12'  =~ /$ra/, "match 2 ok foo12" );
ok( 'nfoo12' !~ /$ra/, "match 2 nok nfoo12" );
ok( 'bar6'   =~ /$ra/, "match 2 ok bar6" );

$ra->reset->filter( sub { not grep { $_ !~ /[\d ]/ } @_ } );

$ra->add( '1 2 4' );

ok( '3 4 1 2' !~ /$ra/, 'filter nok 3 4 1 2' );
ok( '3 1 2 4' =~ /$ra/, 'filter ok 3 1 2 4' );
ok( '5 2 3 4' !~ /$ra/, 'filter ok 5 2 3 4' );

$ra->add( '2 3 a' );

ok( '5 2 3 4' !~ /$ra/, 'filter ok 5 2 3 4 (2)' );
ok( '5 2 3 a' !~ /$ra/, 'filter nok 5 2 3 a' );

$ra->reset->filter( undef );

$ra->add( '1 2 a' );
ok( '5 1 2 a' =~ /$ra/, 'filter now ok 5 1 2 a' );
