# 06_general.t
#
# Test suite for Regexp::Assemble
# Check out the general functionality, now that all the subsystems have been exercised
#
# copyright (C) 2004-2005 David Landgren

use strict;
use Regexp::Assemble;

use Test::More tests => 63;

use constant NR_GOOD  => 45;
use constant NR_BAD   => 529;
use constant NR_ERROR => 0;

my $fixed = 'The scalar remains the same';
$_ = $fixed;

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

ok( not(defined($ra->mvar())), 'mvar() undefined' );

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

$ra->reset->pre_filter( sub { $_[0] !~ /^#/ } );
$ra->add( '#de' );
$ra->add( 'abc' );

ok( '#de' !~ /^$ra$/ );
ok( 'abc' =~ /^$ra$/ );

{
	my $orig = Regexp::Assemble->new;

	my $clone = $orig->clone;
	is_deeply( $orig, $clone, 'clone empty' );
}

{
	my $orig = Regexp::Assemble->new
		->add( qw/ dig dug dog / );

	my $clone = $orig->clone;
	is_deeply( $orig, $clone, 'clone path' );
}

{
	my $orig = Regexp::Assemble->new
		->add( qw/ dig dug dog / );

	my $clone = $orig->clone;
	$orig->add( 'digger' );
	$clone->add( 'digger' );

	is_deeply( $orig, $clone, 'clone then add' );
}

{
	my $orig = Regexp::Assemble->new
		->add( qw/ bird cat dog elephant fox/ );
	my $clone = $orig->clone;
	is_deeply( $orig, $clone, 'clone node' );
}

{
	my $orig = Regexp::Assemble->new
		->add( qw/ after alter amber cheer steer / );

	my $clone = $orig->clone;
	is_deeply( $orig, $clone, 'clone more' );
}

{
	my $r = Regexp::Assemble->new ->add( qw/ dig dug / );
	cmp_ok( $r->dump, 'eq', '[d {i=>[i g] u=>[u g]}]', 'dump path' );
}

{
	my $r = Regexp::Assemble->new ->add( 'a b' );
	cmp_ok( $r->dump, 'eq', q<[a ' ' b]>, 'dump path with space' );
	$r->insert( 'a', ' ', 'b', 'c', 'd' );
	cmp_ok( $r->dump, 'eq', q([a ' ' b {* c=>[c d]}]),
	    'dump path with space 2' );
}

{
	my $r = Regexp::Assemble->new ->add( qw/ dog cat / );
	cmp_ok( $r->dump, 'eq', '[{c=>[c a t] d=>[d o g]}]', 'dump node' );
}

{
	my $r = Regexp::Assemble->new->add( qw/ house home / );
	$r->insert();
	cmp_ok( $r->dump, 'eq', '[{* h=>[h o {m=>[m e] u=>[u s e]}]}]',
		'add opt to path' );
}

{
	my $r = Regexp::Assemble->new->add( qw/ dog cat / );
	$r->insert();
	cmp_ok( $r->dump, 'eq', '[{* c=>[c a t] d=>[d o g]}]',
		'add opt to node' );
}

{
	my $slide = Regexp::Assemble->new;
	cmp_ok( $slide->add( qw/schoolkids acids acidoids/ )->as_string,
		'eq', '(?:ac(?:ido)?|schoolk)ids' );

	cmp_ok( $slide->add( qw/schoolkids acidoids/ )->as_string,
		'eq', '(?:schoolk|acido)ids' );

	cmp_ok( $slide->add( qw/nonschoolkids nonacidoids/ )->as_string,
		'eq', 'non(?:schoolk|acido)ids' );
}

$ra = Regexp::Assemble->new->debug(3);

cmp_ok( $ra->add( qw/ dog darkness doggerel dark / )->as_string,
	'eq',
	'd(?:ark(?:ness)?|og(?:gerel)?)' );

cmp_ok( $ra->add( qw/ limit lit / )->as_string,
	'eq',
	'l(?:im)?it' );

cmp_ok( $ra->add( qw/ seafood seahorse sea / )->as_string,
	'eq',
	'sea(?:horse|food)?' );

cmp_ok( $ra->add( qw/ bird cat dog elephant fox / )->as_string,
	'eq',
	'(?:(?:elephan|ca)t|bird|dog|fox)' );

cmp_ok( $ra->add( qw/ bit bat sit sat fit fat / )->as_string,
	'eq',
	'[bfs][ai]t' );

cmp_ok( $ra->add( qw/ split splat slit slat flat flit / )->as_string,
	'eq',
	'(?:sp?|f)l[ai]t' );

cmp_ok( $ra->add( qw/bcktx bckx bdix bdktx bdkx/ )
    ->as_string, 'eq', 'b(?:d(?:kt?|i)|ckt?)x',
	'bcktx bckx bdix bdktx bdkx' );

cmp_ok( $ra->add( qw/gait grit wait writ /)->as_string,
	'eq', '[gw][ar]it' );

cmp_ok( $ra->add( qw/gait grit lit limit /)->as_string,
	'eq', '(?:l(?:im)?|g[ar])it' );

cmp_ok( $ra->add( qw/bait brit frit gait grit tait wait writ /)->as_string,
	'eq', '(?:[bgw][ar]|fr|ta)it' );

cmp_ok( $ra->add( qw/schoolkids acids acidoids/ )->as_string,
	'eq', '(?:ac(?:ido)?|schoolk)ids' );

cmp_ok( $ra->add( qw/schoolkids acidoids/ )->as_string,
	'eq', '(?:schoolk|acido)ids' );

cmp_ok( $ra->add( qw/nonschoolkids nonacidoids/ )->as_string,
	'eq', 'non(?:schoolk|acido)ids' );

cmp_ok( $ra->add( qw/schoolkids skids acids acidoids/ )->as_string,
	'eq', '(?:s(?:chool)?k|ac(?:ido)?)ids' );

cmp_ok( $ra->add( qw/kids schoolkids skids acids acidoids/ )->as_string,
	'eq', '(?:(?:s(?:chool)?)?k|ac(?:ido)?)ids' );

cmp_ok( $_, 'eq', $fixed, '$_ has not been altered' );
