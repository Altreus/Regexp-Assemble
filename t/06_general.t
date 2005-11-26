# 06_general.t
#
# Test suite for Regexp::Assemble
# Check out the general functionality, now that all the subsystems have been exercised
#
# copyright (C) 2004-2005 David Landgren

use strict;
use Regexp::Assemble;

eval qq{use Test::More tests => 114 };
if( $@ ) {
    warn "# Test::More not available, no tests performed\n";
    print "1..1\nok 1\n";
    exit 0;
}

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

ok( !defined($ra->mvar()), 'mvar() undefined' );

$ra->add( 'bar\\d+' );

ok( 'foo12'  =~ /$ra/, "match 2 ok foo12" );
ok( 'nfoo12' !~ /$ra/, "match 2 nok nfoo12" );
ok( 'bar6'   =~ /$ra/, "match 2 ok bar6" );

$ra->reset->filter( sub { not grep { $_ !~ /[\d ]/ } @_ } );

$ra->add( '1 2 4' );
$ra->insert( '1', '2', '8*' );

ok( '3 4 1 2' !~ /$ra/, 'filter nok 3 4 1 2' );
ok( '3 1 2 4' =~ /$ra/, 'filter ok 3 1 2 4' );
ok( '5 2 3 4' !~ /$ra/, 'filter ok 5 2 3 4' );

$ra->add( '2 3 a+' );
$ra->insert( '2', ' ', '3', ' ', 'a+' );

ok( '5 2 3 4' !~ /$ra/, 'filter ok 5 2 3 4 (2)' );
ok( '5 2 3 aaa' !~ /$ra/, 'filter nok 5 2 3 a+' );

$ra->reset->filter( undef );

$ra->add( '1 2 a+' );
ok( '5 1 2 aaaa' =~ /$ra/, 'filter now ok 5 1 2 a+' );

$ra->reset->pre_filter( sub { $_[0] !~ /^#/ } );
$ra->add( '#de' );
$ra->add( 'abc' );

unlike( '#de', qr/^$ra$/, '#de not matched by comment-filtered assembly' );
like(   'abc', qr/^$ra$/, 'abc matched by comment-filtered assembly' );

{
    my $orig = Regexp::Assemble->new;
    my $clone = $orig->clone;
    is_deeply( $orig, $clone, 'clone empty' );
}

{
    my $orig = Regexp::Assemble->new->add( qw/ dig dug dog / );
    my $clone = $orig->clone;
    is_deeply( $orig, $clone, 'clone path' );
}

{
    my $orig = Regexp::Assemble->new->add( qw/ dig dug dog / );
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

SKIP: {
    # If the Storable module is available, we will have used
    # that above, however, we will not have tested the pure-Perl
    # fallback routines.
       skip( 'Pure-Perl clone() already tested', 2 )
           unless $Regexp::Assemble::have_Storable;

    local $Regexp::Assemble::have_Storable = 0;
    {
        my $orig = Regexp::Assemble->new;
        my $clone = $orig->clone;
        is_deeply( $orig, $clone, 'clone empty' );
    }

    {
        my $orig = Regexp::Assemble->new->add( qw/ dig dug dog / );
        my $clone = $orig->clone;
        is_deeply( $orig, $clone, 'clone path' );
    }

    {
        my $orig = Regexp::Assemble->new->add( qw/ dig dug dog / );
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
        'eq', '(?:ac(?:ido)?|schoolk)ids', 'schoolkids acids acidoids' );

    cmp_ok( $slide->add( qw/schoolkids acidoids/ )->as_string,
        'eq', '(?:schoolk|acido)ids', 'schoolkids acidoids' );

    cmp_ok( $slide->add( qw/nonschoolkids nonacidoids/ )->as_string,
        'eq', 'non(?:schoolk|acido)ids', 'nonschoolkids nonacidoids' );
}

{
    cmp_ok( Regexp::Assemble->new
        ->add( qw( sing singing ))
        ->as_string, 'eq', 'sing(?:ing)?', 'super slide sing singing' # no sliding done
    );

    cmp_ok( Regexp::Assemble->new
        ->add( qw( sing singing sling))
        ->as_string, 'eq', 's(?:(?:ing)?|l)ing',
        'super slide sing singing sling'
    );

    cmp_ok( Regexp::Assemble->new
        ->add( qw( sing singing sling slinging))
        ->as_string, 'eq', 'sl?(?:ing)?ing',
        'super slide sing singing sling slinging'
    );

    cmp_ok( Regexp::Assemble->new
        ->add( qw( sing singing sling slinging sting stinging ))
        ->as_string, 'eq', 's[lt]?(?:ing)?ing',
        'super slide sing singing sling slinging sting stinging'
    );

    cmp_ok( Regexp::Assemble->new
        ->add( qw( sing singing sling slinging sting stinging string stringing swing swinging ))
        ->as_string, 'eq', 's(?:[lw]|tr?)?(?:ing)?ing',
        'super slide sing singing sling slinging sting stinging string stringing swing swinging'
    );
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

{
    my $re = Regexp::Assemble->new( flags => 'i' )->add( qw/ ^ab ^are de / );
    ok( 'able'  =~ /$re/, '{^ab ^are de} /i matches able' );
    ok( 'About' =~ /$re/, '{^ab ^are de} /i matches About' );
    ok( 'bare'  !~ /$re/, '{^ab ^are de} /i fails bare' );
    ok( 'death' =~ /$re/, '{^ab ^are de} /i matches death' );
    ok( 'DEEP'  =~ /$re/, '{^ab ^are de} /i matches DEEP' );
}

{
    my $re = Regexp::Assemble->new->add( qw/abc def ghi/ );
    cmp_ok( $re->{stats_add},    '==', 3, "stats add 3x3" );
    cmp_ok( $re->{stats_raw},    '==', 9, "stats raw 3x3" );
    cmp_ok( $re->{stats_cooked}, '==', 9, "stats cooked 3x3" );
    ok( !defined($re->{stats_dup}), "stats dup 3x3" );

    $re->add( 'de' );
    cmp_ok( $re->{stats_add},    '==',  4, "stats add 3x3 +1" );
    cmp_ok( $re->{stats_raw},    '==', 11, "stats raw 3x3 +1" );
    cmp_ok( $re->{stats_cooked}, '==', 11, "stats cooked 3x3 +1" );
}

{
    my $re = Regexp::Assemble->new->add( '\\Qabc.def.ghi\\E' );
    cmp_ok( $re->{stats_add},    '==', 1, "stats add qm" );
    cmp_ok( $re->{stats_raw},    '==', 15, "stats raw qm" );
    cmp_ok( $re->{stats_cooked}, '==', 13, "stats cooked qm" );
    ok( !defined($re->{stats_dup}), "stats dup qm" );
}

{
    my $re = Regexp::Assemble->new->add( 'abc\\,def', 'abc\\,def' );
    cmp_ok( $re->{stats_add},    '==',  1, "stats add unqm dup" );
    cmp_ok( $re->{stats_raw},    '==', 16, "stats raw unqm dup" );
    cmp_ok( $re->{stats_cooked}, '==',  7, "stats cooked unqm dup" );
    cmp_ok( $re->{stats_dup},    '==',  1, "stats dup unqm dup" );
    cmp_ok( $re->stats_length,   '==',  0, "stats_length unqm dup" );

    my $str = $re->as_string;
    cmp_ok( $str, 'eq', 'abc,def', "stats str unqm dup" );
    cmp_ok( $re->stats_length, '==', 7, "stats len unqm dup" );
}

{
    my $re = Regexp::Assemble->new->add( '' );
    cmp_ok( $re->{stats_add}, '==', 1, "stats add empty" );
    cmp_ok( $re->{stats_raw}, '==', 0, "stats raw empty" );
    ok( !defined($re->{stats_cooked}), "stats cooked empty" );
    ok( !defined($re->{stats_dup}),    "stats dup empty" );
}

{
    my $re = Regexp::Assemble->new;
    cmp_ok( $re->stats_add,    '==', 0, "stats_add empty" );
    cmp_ok( $re->stats_raw,    '==', 0, "stats_raw empty" );
    cmp_ok( $re->stats_cooked, '==', 0, "stats_cooked empty" );
    cmp_ok( $re->stats_dup,    '==', 0, "stats_dup empty" );
    cmp_ok( $re->stats_length, '==', 0, "stats_length empty" );

    my $str = $re->as_string;
    cmp_ok( $str, 'eq', '^a\\bz', "stats str empty" ); # tricky!
    cmp_ok( $re->stats_length, '==', 0, "stats len empty" );
}

{
    my $re = Regexp::Assemble->new->add( '\\Q.+\\E', '\\Q.+\\E', '\\Q.*\\E' );
    cmp_ok( $re->stats_add,    '==',  2, "stats_add 2" );
    cmp_ok( $re->stats_raw,    '==', 18, "stats_raw 2" );
    cmp_ok( $re->stats_cooked, '==',  8, "stats_cooked 2" );
    cmp_ok( $re->stats_dup,    '==',  1, "stats_dup 2" );
    cmp_ok( $re->stats_length, '==',  0, "stats_length 2" );

    my $str = $re->as_string;
    cmp_ok( $str, 'eq', '\\.[*+]', "stats str 2" );
    cmp_ok( $re->stats_length, '==', 6, "stats len 2 <$str>" );
}

cmp_ok( $_, 'eq', $fixed, '$_ has not been altered' );
