# 00_basic.t
#
# Test suite for Regexp::Assemble
# Make sure the basic stuff works
#
# The fact that many of these tests access object internals directly
# does not constitute a coding recommendation.
#
# copyright (C) 2004-2005 David Landgren

use strict;
use constant TEST_560 => 3; # tests to ignore when running under 5.6.0

use Test::More tests => 127 + TEST_560;

use Regexp::Assemble;

my $fixed = 'The scalar remains the same';
$_ = $fixed;

diag( "testing Regexp::Assemble v$Regexp::Assemble::VERSION" );

my $rt = Regexp::Assemble->new;
ok( defined($rt), 'new() defines something' );
ok( ref($rt) eq 'Regexp::Assemble', 'new() returns a Regexp::Assemble object' );

ok( length(Regexp::Assemble::Default_Lexer) > 0,
	'default lexer is something' );

ok( ref( $rt->_path ) eq 'ARRAY', '_path() isa ARRAY' );
ok( 0 == @{$rt->_path}, '_path() is empty' );

my $have_Test_Deep = do {
    eval { require Test::Deep; import Test::Deep };
    $@ ? 0 : 1;
};

{
    my $r = Regexp::Assemble->new( chomp => 1 );
    ok( $r->{chomp} == 1, 'chomp new(1)' );
    $r->chomp( 0 );
    ok( $r->{chomp} == 0, 'chomp(0)' );
    $r->chomp();
    ok( $r->{chomp} == 1, 'chomp()' );
}

{
    my $r = Regexp::Assemble->new( reduce => 1 );
    ok( $r->{reduce} == 1, 'reduce new(1)' );
    $r->reduce( 0 );
    ok( $r->{reduce} == 0, 'reduce(0)' );
    $r->reduce();
    ok( $r->{reduce} == 1, 'reduce()' );
}

{
    my $r = Regexp::Assemble->new( mutable => 1 );
    ok( $r->{mutable} == 1, 'mutable new(1)' );
    $r->mutable( 0 );
    ok( $r->{mutable} == 0, 'mutable(0)' );
    $r->mutable();
    ok( $r->{mutable} == 1, 'mutable()' );
}

{
    my $r = Regexp::Assemble->new( flags => 'i' );
    ok( $r->{flags} eq 'i', 'flags new(i)' );
    $r->flags( 'sx' );
    ok( $r->{flags} eq 'sx', 'flags(sx)' );
    $r->flags( '' );
    ok( $r->{flags} eq '', q{flags('')} );
    $r->flags( 0 );
    ok( $r->{flags} eq '0', 'flags(0)' );
    $r->flags();
    ok( $r->{flags} eq '', q{flags()} );
}

{
    my $r = Regexp::Assemble->new( track => 2 );
    ok( $r->{track} == 2, 'track new(n)' );
    $r->track( 0 );
    ok( $r->{track} == 0, 'track(0)' );
    $r->track( 1 );
    ok( $r->{track} == 1, 'track(1)' );
    $r->track( 0 );
    ok( $r->{track} == 0, 'track(0) 2nd' );
    $r->track();
    ok( $r->{track} == 1, 'track()' );
}

{
    my $r = Regexp::Assemble->new( mutable => 2 );
    ok( $r->{mutable} == 2, 'mutable new(n)' );
    $r->mutable( 0 );
    ok( $r->{mutable} == 0, 'track(0)' );
}

{
    my $r = Regexp::Assemble->new( reduce => 2 );
    ok( $r->{reduce} == 2, 'reduce new(n)' );
    $r->reduce( 0 );
    ok( $r->{reduce} == 0, 'reduce(0)' );
}

{
    my $r = Regexp::Assemble->new( debug => 15 );
    ok( $r->{debug} == 15, 'debug new(n)' );
    $r->debug( 0 );
    ok( $r->{debug} == 0, 'debug(0)' );
	$r->debug( 4 );
    ok( $r->{debug} == 4, 'debug(4)' );
	$r->debug();
    ok( $r->{debug} == 0, 'debug()' );
}

{
    my $r = Regexp::Assemble->new( pre_filter => sub { undef } );
    ok( ref($r->{pre_filter}) eq 'CODE', 'pre_filter new(n)' );
    $r->pre_filter( undef );
    ok( !defined $r->{pre_filter}, 'pre_filter(0)' );
}

{
    my $r = Regexp::Assemble->new( filter => sub { undef } );
    ok( ref($r->{filter}) eq 'CODE', 'filter new(n)' );
    $r->filter( undef );
    ok( !defined $r->{filter}, 'filter(0)' );
}

ok( Regexp::Assemble::_node_key(
        { a => 1, b=>2, c=>3 }
    ) eq 'a', '_node_key(1)'
);

ok( Regexp::Assemble::_node_key(
        { b => 3, c=>2, z=>1 }
    ) eq 'b', '_node_key(2)'
);

ok( Regexp::Assemble::_node_key(
        { a => 1, 'a.' => 2, b => 3 }
    ) eq 'a', '_node_key(3)'
);

ok( Regexp::Assemble::_node_key(
        { '' => undef, a => 1, 'a.' => 2, b => 3 }
    ) eq 'a', '_node_key(4)'
);

ok( Regexp::Assemble::_node_key(
        { '' => undef, abc => 1, def => 2, g => 3 }
    ) eq 'abc', '_node_key(5)'
);

ok( Regexp::Assemble::_node_offset(
        [ 'a', 'b', '\\d+', 'e', '\\d' ]
    ) == -1, '_node_offset(1)'
);

ok( Regexp::Assemble::_node_offset(
        [ {x => ['x'], '' => undef}, 'a', 'b', '\\d+', 'e', '\\d' ]
    ) == 0, '_node_offset(2)'
);

ok( Regexp::Assemble::_node_offset(
        [ 'a', 'b', '\\d+', 'e', {a => 1, b => 2}, 'x', 'y', 'z' ]
    ) == 4, '_node_offset(3)'
);

ok( Regexp::Assemble::_node_offset(
        [ { z => 1, x => 2 }, 'b', '\\d+', 'e', {a => 1, b => 2}, 'z' ]
    ) == 0, '_node_offset(4)'
);

ok( Regexp::Assemble::_node_offset(
        [ [ 1, 2, 3, {a => ['a'], b=>['b']} ], 'a', { z => 1, x => 2 } ]
    ) == 2, '_node_offset(5)'
);

ok( Regexp::Assemble::_node_eq(
        {},
        {}
    ) == 1, '{} eq {}'
);

ok( Regexp::Assemble::_node_eq(
        undef,
        {}
    ) == 0, 'undef ne {}'
);

ok( Regexp::Assemble::_node_eq(
        {},
        undef
    ) == 0, '{} ne undef'
);

ok( Regexp::Assemble::_node_eq(
        undef,
        undef
    ) == 0, 'undef ne undef'
);

ok( Regexp::Assemble::_node_eq(
        [],
        []
    ) == 1, '[] eq []'
);

ok( Regexp::Assemble::_node_eq(
        [],
        {}
    ) == 0, '[] ne {}'
);

ok( Regexp::Assemble::_node_eq(
        {},
        []
    ) == 0, '{} ne []'
);

ok( Regexp::Assemble::_node_eq(
        [0],
        [0],
    ) == 1, 'eq [0]'
);

ok( Regexp::Assemble::_node_eq(
        [0, 1, 2],
        [0, 1, 2],
    ) == 1, 'eq [0,1,2]'
);

ok( Regexp::Assemble::_node_eq(
        [0, 1, 2],
        [0, 1, 2, 3],
    ) == 0, 'ne [0,1,2,3]'
);

ok( Regexp::Assemble::_node_eq(
        {'a'=>['a','b']},
        {'a'=>['a','b']},
    ) == 1, 'eq {a}'
);

ok( Regexp::Assemble::_node_eq(
        {'a'=>['a','b']},
        {'a'=>['a','b'], '' => undef},
    ) == 0, 'ne {a}'
);

ok( Regexp::Assemble::_node_eq(
        {'a'=>['a','b'], 'b'=>['b','c']},
        {'a'=>['a','b'], 'b'=>['b','c']},
    ) == 1, 'eq {a,b}'
);

ok( Regexp::Assemble::_node_eq(
        [{'a'=>['a','b'], 'b'=>['b','c']}, {'z'=>['z','y'], 'm'=>['m','n']}],
        [{'a'=>['a','b'], 'b'=>['b','c']}, {'z'=>['z','y'], 'm'=>['m','n']}],
    ) == 1, 'eq {a,b},{z,m}'
);

ok( Regexp::Assemble::_node_eq(
        [{'a'=>['a','b'], 'b'=>['b','c']}, {'z'=>['z','y'], 'm'=>['m','n']}],
        [{'a'=>['a','b'], 'b'=>['b','c']}, {'z'=>['z','y'], 'm'=>['m','n','o']}],
    ) == 0, 'ne {a,b},{z,m}'
);

ok( Regexp::Assemble::_node_eq(
        {''=>undef, 'a'=>['a','b']},
        {''=>undef, 'a'=>['a','b']},
    ) == 1, '{eq {* a}'
);

ok( Regexp::Assemble::_node_eq(
        ['z','\\d+', {'a'=>['a','b']}],
        ['z','\\d+', {'a'=>['a','b']}],
    ) == 1, 'eq [z \d+ {a}]'
);

ok( Regexp::Assemble::_node_eq(
        ['z','\\d+', {'a'=>['a','b'], 'z'=>['z','y','x']}],
        ['z','\\d+', {'a'=>['a','b'], 'z'=>['z','y','x']}],
    ) == 1, 'eq [z \d+ {a,z}]'
);

cmp_ok( Regexp::Assemble::_make_class( qw/ a b c / ),
	'eq', '[abc]', '_make_class a b c'
);

cmp_ok( Regexp::Assemble::_make_class( qw/ a a c / ),
	'eq', '[ac]', '_make_class a a c'
);

cmp_ok( Regexp::Assemble::_make_class( qw/ 0 1 2 3 4 5 6 7 8 9 / ),
	'eq', '\\d', '_make_class 0 1 ... 9'
);

cmp_ok( Regexp::Assemble::_make_class( qw/ \\d \\D / ),
	'eq', '.', '_make_class \\d \\D'
);

cmp_ok( Regexp::Assemble::_make_class( qw/ \\s \\S / ),
	'eq', '.', '_make_class \\s \\S'
);

cmp_ok( Regexp::Assemble::_make_class( qw/ \\w \\W / ),
	'eq', '.', '_make_class \\w \\W'
);

cmp_ok( Regexp::Assemble::_make_class( qw/ \\d 5 a / ),
	'eq', '[\\da]', '_make_class \\d 5 a'
);

cmp_ok( Regexp::Assemble::_make_class( qw/ a z - / ),
	'eq', '[-az]', '_make_class a z -'
);

cmp_ok( Regexp::Assemble::_make_class( qw/ a z ^ / ),
	'eq', '[az^]', '_make_class a z ^'
);

cmp_ok( Regexp::Assemble::_make_class( qw/ a z ^ - / ),
	'eq', '[-az^]', '_make_class a z ^ -'
);

cmp_ok( Regexp::Assemble::_make_class( qw/ \\. \\+ / ),
	'eq', '[+.]', '_make_class \\. \\+'
);


{
	my $r = Regexp::Assemble->new;
	is_deeply( [$r->_lex( '' )], [], '_lex empty string' );

	my $str = 'abc';
	is_deeply( [$r->_lex( $str )],
		[ 'a', 'b', 'c' ],
		"_lex $str",
	);

	$str = 'a+b*c?';
	is_deeply( [$r->_lex( $str )],
		[ 'a+', 'b*', 'c?' ],
		"_lex $str",
	);

	$str = 'a+\\d+';
	is_deeply( [$r->_lex( $str )],
		[ 'a+', '\\d+' ],
		"_lex $str",
	);

	$str = 'a+?b*?c??';
	is_deeply( [$r->_lex( $str )],
		[ 'a+?', 'b*?', 'c??' ],
		"_lex $str",
	);

	$str = 'abc[def]g';
	is_deeply( [$r->_lex( $str )],
		[ 'a', 'b', 'c', '[def]', 'g' ],
		"_lex $str",
	);

	$str = '(?:ab)?c[def]+g';
	is_deeply( [$r->_lex( $str )],
		[ '(?:ab)?', 'c', '[def]+', 'g' ],
		"_lex $str",
	);

	$str = 'abc[def]g(?:hi[jk]lm[no]p)';
	is_deeply( [$r->_lex( $str )],
		[ 'a', 'b', 'c', '[def]', 'g', '(?:hi[jk]lm[no]p)' ],
		"_lex $str",
	);

	$str = 'abc[def]g[,.%\\]$&].\\.$';
	is_deeply( [$r->_lex( $str )],
		[ 'a', 'b', 'c', '[def]', 'g', '[,.%\\]$&]', '.', '\\.', '$' ],
		"_lex $str",
	);

	$str = '\\w+\\d{2,}\\s+?\\w{1,100}?'; is_deeply( [$r->_lex( $str  )],
		[ '\\w+', '\\d{2,}', '\\s+?', '\\w{1,100}?' ],
		"_lex $str",
	);

	#$str = '\\012+\\.?\\xae+\\x{dead}\\x{beef}+';
	#is_deeply( [$r->_lex( $str  )],
	#    [ '\\012+', '\\.?', '\\xae+', '\\x{dead}', '\\x{beef}+' ],
	#    "_lex $str",
	#);

	$str = '\\c[\\ca\\c]\\N{foo}';
	is_deeply( [$r->_lex( $str  )],
		[ '\\c[', '\\ca', '\\c]', '\\N{foo}' ],
		"_lex $str",
	);

	$str = '\\b(?:ab\(cd\)ef)+?(?:ab[cd]+e)*';
	is_deeply( [$r->_lex( $str  )],
		[ '\\b', '(?:ab\(cd\)ef)+?', '(?:ab[cd]+e)*' ],
		"_lex $str",
	);

	$str = '\\A[^bc\]\d]+\\Z';
	is_deeply( [$r->_lex( $str  )],
		[ '\\A', '[^bc\]\d]+', '\\Z' ],
		"_lex $str",
	);

	$str = 'a\\d+\\w*:[\\d\\s]+.z(?!foo)d';
	is_deeply( [$r->_lex( $str  )],
		[ 'a', '\\d+', '\\w*', ':', '[\\d\\s]+', '.', 'z', '(?!foo)', 'd' ],
		"_lex $str",
	);
}

{
	my $r = Regexp::Assemble->new->debug(4);

	my $str = 'a\\Q+x*\\Eb+';
	is_deeply( [$r->_lex( $str )], [ 'a', '\\Q+x*\\E', 'b+' ], "_lex $str" );

	$str = 'a\\Q+x*b+';
	is_deeply( [$r->_lex( $str  )], [ 'a', '\\Q+x*b+' ], "_lex $str" );

	$str = 'a\\Eb';
	is_deeply( [$r->_lex( $str  )], [ 'a', '\\E', 'b', ], "_lex $str" );

	$str = 'a\\Q+x*\\Eb+';
	$r->reset->debug(4)->add( $str );
	is_deeply( $r->_path, [ 'a', '\\+', 'x', '\\*', 'b+' ], "add $str" );

	$str = 'a\\Q+x*b+';
	$r->reset->debug(0)->add( $str );
	is_deeply( $r->_path, [ 'a', '\\+', 'x', '\\*', 'b', '\\+' ], "add $str" );

	$str = 'a\\Eb';
	$r->reset->add( $str );
	is_deeply( $r->_path, [ 'a', 'b', ], "add $str" );
}

{
	my $path;

	$path = [];
	is_deeply( $path, Regexp::Assemble::_path_copy($path),
		'_path_copy([])' );

	$path = [0, qw[ab cd ef]];
	is_deeply( $path, Regexp::Assemble::_path_copy($path),
		'_path_copy(0 ab cd ef)' );

	$path = {};
	is_deeply( $path, Regexp::Assemble::_node_copy($path),
		'_node_copy({})' );

	$path = {'a' => [qw[a bb ccc]], 'b'=>[qw[b cc ddd]]};
	is_deeply( $path, Regexp::Assemble::_node_copy($path),
		'_node_copy({a,b})' );

	$path = [
		{'c'=>['c','d'],'e'=>['e','f']},
		't',
		{'d'=>['d','f'],'b'=>['b',0]},
		{ '' => undef, 'a' => ['a']},
	];
	is_deeply( $path, Regexp::Assemble::_path_copy($path),
		'_path_copy({c,e} t {d,b} {* a}' );

	$path = [
		[0, 1, 2],
		['a','b','c'],
		['d',{'e'=>['e','f'],'g'=>['g','h']}],
	];
	is_deeply( $path, Regexp::Assemble::_path_copy($path),
		'_path_copy(ab cd ef {* a})' );
}

is_deeply( $rt->_path, [], 'path is empty' );

is_deeply( Regexp::Assemble::_unrev_path(
    [0, 1], 0, 0),
    [1, 0], 'path(0,1)' );

is_deeply( Regexp::Assemble::_unrev_path(
    [qw[ ab cd ef ]], 0, 0),
    [qw[ ef cd ab ]], 'path(ab,cd,ef)' );

is_deeply( Regexp::Assemble::_unrev_path( Regexp::Assemble::_unrev_path(
    [qw[ ab cd ef ]], 0, 0), 0, 0),
    [qw[ ab cd ef ]], 'path(ab,cd,ef) back' );

is_deeply( Regexp::Assemble::_unrev_path(
    [qw[ ab cd ef \\d+ \\D ghi jkl mno ]], 0, 0),
    [qw[ mno jkl ghi \\D \\d+ ef cd ab ]], 'path(ab cd...)' );

is_deeply( Regexp::Assemble::_unrev_path( Regexp::Assemble::_unrev_path(
    [qw[ ab cd ef \\d+ \\D ghi jkl mno ]], 0, 0), 0, 0),
    [qw[ ab cd ef \\d+ \\D ghi jkl mno ]], 'path(ab cd...) back' ),

is_deeply( Regexp::Assemble::_unrev_node(
    { 0 => [0, 1]}, 0, 0),
    { 1 => [1, 0]},
    'node(0)' );

is_deeply( Regexp::Assemble::_unrev_node(
    { 0 => [0, 1], 2 => [2, 0]}, 0, 0),
    { 1 => [1, 0], 0 => [0, 2]},
    'node(0,2)' );

is_deeply( Regexp::Assemble::_unrev_node(
    { '' => undef, a => [qw[a b]] }, 0, 0),
    { '' => undef, b => [qw[b a]] },
    'node(*,a,b)' );

is_deeply( Regexp::Assemble::_unrev_node(
    { '' => undef, a => [qw[a b]], b => [qw[b c d e f g]] }, 0, 0),
    { '' => undef, b => [qw[b a]], g => [qw[g f e d c b]] },
    'node(*a,b2)' );

is_deeply( Regexp::Assemble::_unrev_path(
    [{x => [qw[x 0]], '' => undef }], 0, 0 ),
    [{0 => [qw[0 x]], '' => undef }], 'node(* 0)' );

is_deeply( Regexp::Assemble::_unrev_node(
    { ab => [qw[ab bc]], bc => [qw[bc cd de ef fg gh]], ef => [qw[ef gh ij]] }, 0, 0),
    { bc => [qw[bc ab]], gh => [qw[gh fg ef de cd bc]], ij => [qw[ij gh ef]] },
    'node(ab,bc,ef)' );

is_deeply( Regexp::Assemble::_unrev_path(
    [qw[a b], {c=>[qw[c d e]], f=>[qw[f g h]], i=>[qw[i j], {k => [qw[k l m]], n=>[qw[n o p]]}, 'x' ]}], 0, 0),
    [{e=>[qw[e d c]], h=>[qw[h g f]], x=>['x', {m=>[qw[m l k]], p=>[qw[p o n]]}, qw[j i]]}, qw[b a]],
    'path(node(path))');

{
	my $ra = Regexp::Assemble->new
		->add( 'refused' )
		->add( 'fused' )
		->add( 'used' );
	$ra->_reduce;

	ok( eq_set(
		[keys %{Regexp::Assemble::_lookahead($ra->{path}[0])}],
		['f', 'r']),
		'_lookahead refused/fused/used'
	);

	$ra = Regexp::Assemble->new
		->add( 'refused' )
		->add( 'reamused' )
		->add( 'fused' )
		->add( 'amused' )
		->add( 'used' );
	$ra->_reduce;

	ok( eq_set(
		[keys %{Regexp::Assemble::_lookahead($ra->{path}[0])}],
		['a', 'f', 'r']),
		'_lookahead reamused/refused/amused/fused/used'
	);

	$ra = Regexp::Assemble->new
		->add( 'cruised' )
		->add( 'bruised' )
		->add( 'hosed' )
		->add( 'gazed' )
		->add( 'used' );
	$ra->_reduce;

	ok( eq_set(
		[keys %{Regexp::Assemble::_lookahead($ra->{path}[0])}],
		['b', 'c', 'g', 'h', 'u']),
		'_lookahead cruised/bruised/hosed/gazed/used'
	);
}

cmp_ok( Regexp::Assemble::_dump( [1, 0, undef] ),
	'eq', '[1 0 *]', 'dump 1'
);

cmp_ok( Regexp::Assemble::_dump( [1, 0, q{ }] ),
	'eq', q{[1 0 ' ']}, 'dump 2'
);

cmp_ok( Regexp::Assemble::_dump( {a => ['a', 'b'], b => ['b']} ),
	'eq', '{a=>[a b] b=>[b]}', 'dump 3'
);

cmp_ok( Regexp::Assemble::_combine( '?=', qw/ c a b / ),
	'eq', '(?=[abc])', '_combine c a b'
);

cmp_ok( Regexp::Assemble::_combine( '?=', qw/ c ab de / ),
	'eq', '(?=ab|de|c)', '_combine c ab de'
);

cmp_ok( Regexp::Assemble::_combine( '?=', qw/ in og / ),
	'eq', '(?=in|og)', '_combine in og'
);

cmp_ok( Regexp::Assemble::_combine( '?=', qw/ in og j k l / ),
	'eq', '(?=[jkl]|in|og)', '_combine in og j k l'
);

cmp_ok( Regexp::Assemble::_combine( '?=', qw/ in og 0 1 2 3 4 5 6 7 8 9 / ),
	'eq', '(?=\d|in|og)', '_combine in og 0 1 ... 9'
);

SKIP: {
    skip 'backslashes in qw// operator give incorrect results in 5.6.0', TEST_560 if $] eq '5.006';

    is_deeply( Regexp::Assemble::_unrev_path(
        [{x1     => ['x1', 'z\\d'], '' => undef }], 0, 0 ),
        [{'z\\d' => ['z\\d', 'x1'], '' => undef }], 'node(* metachar)' );

    is_deeply( Regexp::Assemble::_unrev_path(
        [{x     => [qw[x \\d]], '' => undef }], 0, 0 ),
        [{'\\d' => [qw[\\d x]], '' => undef }], 'node(* metachar) 2' );

    is_deeply( Regexp::Assemble::_unrev_path(
        [qw[ ab cd ef ], {x1 => [qw[x1 y2 z\\d]], mx => [qw[mx us ca]] }], 0, 0 ),
        [{ 'z\\d' => [qw[z\\d y2 x1]], ca => [qw[ca us mx]]}, qw[ef cd ab]], 'path(node)' );
}

eval {
	my $ra = Regexp::Assemble->new;
	$ra->Default_Lexer( qr/\d+/ );
};

like( $@,
	qr/^Don't pass a Regexp::Assemble to Default_Lexer\n\s+at \S+ line \d+/m,
	'Default_Lexer die'
);

cmp_ok( $_, 'eq', $fixed, '$_ has not been altered' );

