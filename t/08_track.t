# 08_track.t
#
# Test suite for Regexp::Assemble
# Tests to see that tracked patterns behave themselves
#
# copyright (C) 2004 David Landgren

use strict;
use constant TESTS => 36;
use Test::More tests => TESTS;
use Regexp::Assemble;

SKIP: {

skip '(?{...}) is borked below 5.6.0', TESTS if $] < 5.006;

{
    my $re = Regexp::Assemble->new( track=>1 )
        ->add( qw/dog dogged fish fetish flash fresh/ );
    $re->add('foolish-\\d+');
    ok( $re->match('dog'), 're pattern-1 dog match' );
    SKIP: {
        skip 'matched() is not implemented in 5.6.0', 1 if $] eq '5.006';
        ok( $re->matched eq 'dog', 're pattern-1 dog matched' );
    }
    ok( $re->match('dogged'), 're pattern-1 dogged match' );
    SKIP: {
        skip 'matched() is not implemented in 5.6.0', 1 if $] eq '5.006';
        ok( $re->matched eq 'dogged', 're pattern-1 dogged matched' );
    }
    ok( $re->match('fetish'), 're pattern-1 fetish match' );
    SKIP: {
        skip 'matched() is not implemented in 5.6.0', 1 if $] eq '5.006';
        ok( $re->matched eq 'fetish', 're pattern-1 fetish matched' );
    }
    ok( $re->match('foolish-245'), 're pattern-1 foolish-\\d+ match' );
    SKIP: {
        skip 'matched() is not implemented in 5.6.0', 1 if $] eq '5.006';
        ok( $re->matched eq 'foolish-\\d+', 're pattern-1 foolish-\\d+ matched' );
    }
    ok( !defined($re->match('foolish-')), 're pattern-1 foolish-\\d+ 4' );
    SKIP: {
        skip 'matched() is not implemented in 5.6.0', 1 if $] eq '5.006';
        ok( !defined($re->matched), 're pattern-1 foolish-\\d+ 5' );
    }
    ok( do {use re 'eval'; 'cat' !~ /$re/}, 're pattern-1 cat' );
    ok( do {use re 'eval'; 'foolish-808' =~ /$re/}, 're pattern-1 foolish-808' );
}

{
    my $re = Regexp::Assemble->new( track=>1 )
        ->add( '^a-\\d+$' )
        ->add( '^a-\\d+-\\d+$' );
    ok( !defined $re->match('foo'), 'match pattern-2 foo' );
    ok( defined $re->match('a-22-44'), 'match pattern-2 a-22-44' );
    if( $] eq '5.006' ) {
        ok( $re->match('a-22-55555') == 1, 're pattern-2 a-22-55555' );
    }
    else {
        ok( $re->match('a-22-55555') eq '^a-\\d+-\\d+$', 're pattern-2 a-22-55555' );
    }
    ok( $re->match('a-000'), 're pattern-2 a-000 match' );
    SKIP: {
        skip 'matched() is not implemented in 5.6.0', 1 if $] eq '5.006';
        ok( $re->matched eq '^a-\\d+$', 're pattern-2 a-000 matched' );
    }
}

{
    my $re = Regexp::Assemble->new( track=>1 )
        ->add( '^b-(\\d+)$' )
        ->add( '^b-(\\d+)-(\\d+)$' )
    ;
    ok( !defined $re->match('foo'), 'match pattern-3 foo' );
    ok( defined $re->match('b-34-56'), 'match pattern-3 b-34-56' );
    ok( $re->mvar(0) eq 'b-34-56', 'match pattern-3 capture 1' );
    ok( $re->mvar(1) == 34, 'match pattern-3 capture 2' );
    ok( $re->mvar(2) == 56, 'match pattern-3 capture 3' );
    ok( defined $re->match('b-789'), 'match pattern-3 b-789' );
    ok( $re->mvar(0) eq 'b-789', 'match pattern-3 capture 4' );
    ok( $re->mvar(1) == 789, 'match pattern-3 capture 5' );
    ok( !defined($re->mvar(2)), 'match pattern-3 undef' );
}

{
    my $re = Regexp::Assemble->new( track=>1 )
        ->add( '^c-(\\d+)$' )
        ->add( '^c-(\\w+)$' )
        ->add( '^c-([aeiou])-(\\d+)$' )
    ;
    ok( !defined $re->match('foo'), 'match pattern-4 foo' );
    ok( !defined $re->mvar(2), 'match pattern-4 foo novar' );
    my $target = 'c-u-350';
    ok( defined $re->match($target), "match pattern-4 $target" );
    ok( $re->mvar(0) eq $target, 'match pattern-4 capture 1' );
    ok( $re->mvar(1) eq 'u', 'match pattern-4 capture 2' );
    ok( $re->mvar(2) == 350, 'match pattern-4 capture 3' );
    $target = 'c-2048';
    ok( defined $re->match($target), "match pattern-4 $target" );
    ok( $re->mvar(0) eq $target, 'match pattern-4 capture 4' );
    ok( $re->mvar(1) == 2048, 'match pattern-4 capture 5' );
    ok( !defined($re->mvar(2)), 'match pattern-4 undef' );
}

} # SKIP
