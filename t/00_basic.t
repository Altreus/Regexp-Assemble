# 00_basic.t
#
# Test suite for Regexp::Assemble
# Make sure the basic stuff works
#
# copyright (C) 2004 David Landgren

use strict;
use constant TEST_DEEP_COUNT => 32;

use Test::More tests => 28 + TEST_DEEP_COUNT;

use Regexp::Assemble;

my $rt = Regexp::Assemble->new;

ok( defined($rt), 'new() defines something' );
ok( ref($rt) eq 'Regexp::Assemble', 'new() returns a Regexp::Assemble object' );

ok( ref( $rt->_path ) eq 'ARRAY', '_path() isa ARRAY' );
ok( 0 == @{$rt->_path}, '_path() is empty' );

my $have_Test_Deep = do {
    eval { require Test::Deep; import Test::Deep };
    $@ ? 0 : 1;
};

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
    ) == 1, 'eq {}'
);

ok( Regexp::Assemble::_node_eq(
        [],
        []
    ) == 1, 'eq []'
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
        {'a'=>['a','b'],''=>undef,},
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

SKIP: {
    skip 'Test::Deep not installed on this system', TEST_DEEP_COUNT
        unless $have_Test_Deep;

    {
        my $r = Regexp::Assemble->new;
        my $str = 'abc';
        cmp_deeply( [$r->_lex( $str )],
            [ 'a', 'b', 'c' ],
            "_lex $str",
        );

        $str = 'a+b*c?';
        cmp_deeply( [$r->_lex( $str )],
            [ 'a+', 'b*', 'c?' ],
            "_lex $str",
        );

        $str = 'a+?b*?c??';
        cmp_deeply( [$r->_lex( $str )],
            [ 'a+?', 'b*?', 'c??' ],
            "_lex $str",
        );

        $str = 'abc[def]g';
        cmp_deeply( [$r->_lex( $str )],
            [ 'a', 'b', 'c', '[def]', 'g' ],
            "_lex $str",
        );

        $str = '(?:ab)?c[def]+g';
        cmp_deeply( [$r->_lex( $str )],
            [ '(?:ab)?', 'c', '[def]+', 'g' ],
            "_lex $str",
        );

        $str = 'abc[def]g(?:hi[jk]lm[no]p)';
        cmp_deeply( [$r->_lex( $str )],
            [ 'a', 'b', 'c', '[def]', 'g', '(?:hi[jk]lm[no]p)' ],
            "_lex $str",
        );

        $str = 'abc[def]g[,.%\\]$&].\\.$';
        cmp_deeply( [$r->_lex( $str )],
            [ 'a', 'b', 'c', '[def]', 'g', '[,.%\\]$&]', '.', '\\.', '$' ],
            "_lex $str",
        ) or print join( ' ' => $r->_lex($str)), "\n";

        $str = '\\w+\\d{2,}\\s+?\\w{1,100}?'; cmp_deeply( [$r->_lex( $str  )],
            [ '\\w+', '\\d{2,}', '\\s+?', '\\w{1,100}?' ],
            "_lex $str",
        );

        $str = '\\012+\\.?\\xae+\\x{dead}\\x{beef}+';
        cmp_deeply( [$r->_lex( $str  )],
            [ '\\012+', '\\.?', '\\xae+', '\\x{dead}', '\\x{beef}+' ],
            "_lex $str",
        );

        $str = '\\c[\\ca\\c]\\N{foo}';
        cmp_deeply( [$r->_lex( $str  )],
            [ '\\c[', '\\ca', '\\c]', '\\N{foo}' ],
            "_lex $str",
        );

        $str = '\\b(?:ab\(cd\)ef)+?(?:ab[cd]+e)*';
        cmp_deeply( [$r->_lex( $str  )],
            [ '\\b', '(?:ab\(cd\)ef)+?', '(?:ab[cd]+e)*' ],
            "_lex $str",
        ) or print '# ', join( ' ' => $r->_lex($str)), "\n";

        $str = '\\A[^bc\]\d]+\\Z';
        cmp_deeply( [$r->_lex( $str  )],
            [ '\\A', '[^bc\]\d]+', '\\Z' ],
            "_lex $str",
        ) or print '# ', join( ' ' => $r->_lex($str)), "\n";

        $str = 'a\\d+\\w*:[\\d\\s]+.z(?!foo)d';
        cmp_deeply( [$r->_lex( $str  )],
            [ 'a', '\\d+', '\\w*', ':', '[\\d\\s]+', '.', 'z', '(?!foo)', 'd' ],
            "_lex $str",
        ) or print '# ', join( ' ' => $r->_lex($str)), "\n";
    }

    my $path;

    $path = [];
    cmp_deeply( $path, Regexp::Assemble::_path_copy($path),
        '_path_copy([])' );

    $path = [0, qw[ab cd ef]];
    cmp_deeply( $path, Regexp::Assemble::_path_copy($path),
        '_path_copy(0 ab cd ef)' );

    $path = {};
    cmp_deeply( $path, Regexp::Assemble::_node_copy($path),
        '_node_copy({})' );

    $path = {'a' => [qw[a bb ccc]], 'b'=>[qw[b cc ddd]]};
    cmp_deeply( $path, Regexp::Assemble::_node_copy($path),
        '_node_copy({a,b})' );

    $path = [
        {'c'=>['c','d'],'e'=>['e','f']},
        't',
        {'d'=>['d','f'],'b'=>['b',0]},
        { '' => undef, 'a' => ['a']},
    ];
    cmp_deeply( $path, Regexp::Assemble::_path_copy($path),
        '_path_copy({c,e} t {d,b} {* a}' );

    $path = [
        [0, 1, 2],
        ['a','b','c'],
        ['d',{'e'=>['e','f'],'g'=>['g','h']}],
    ];
    cmp_deeply( $path, Regexp::Assemble::_path_copy($path),
        '_path_copy(ab cd ef {* a})' );

    cmp_deeply( $rt->_path, [], 'path is empty' );

    cmp_deeply( Regexp::Assemble::_unrev_path(
        [0, 1], ),
        [1, 0], 'path(0,1)' );

    cmp_deeply( Regexp::Assemble::_unrev_path(
        [qw[ ab cd ef ]], ),
        [qw[ ef cd ab ]], 'path(ab,cd,ef)' );

    cmp_deeply( Regexp::Assemble::_unrev_path( Regexp::Assemble::_unrev_path(
        [qw[ ab cd ef ]], )),
        [qw[ ab cd ef ]], 'path(ab,cd,ef) back' );

    cmp_deeply( Regexp::Assemble::_unrev_path(
        [qw[ ab cd ef \\d+ \\D ghi jkl mno ]], ),
        [qw[ mno jkl ghi \\D \\d+ ef cd ab ]], 'path(ab cd...)' );

    cmp_deeply( Regexp::Assemble::_unrev_path( Regexp::Assemble::_unrev_path(
        [qw[ ab cd ef \\d+ \\D ghi jkl mno ]], )),
        [qw[ ab cd ef \\d+ \\D ghi jkl mno ]], 'path(ab cd...) back' ),

    cmp_deeply( Regexp::Assemble::_unrev_node(
        { 0 => [0, 1]}),
        { 1 => [1, 0]},
        'node(0)' );

    cmp_deeply( Regexp::Assemble::_unrev_node(
        { 0 => [0, 1], 2 => [2, 0]}),
        { 1 => [1, 0], 0 => [0, 2]},
        'node(0,2)' );

    cmp_deeply( Regexp::Assemble::_unrev_node(
        { '' => undef, a => [qw[a b]] }),
        { '' => undef, b => [qw[b a]] },
        'node(*,a,b)' );

    cmp_deeply( Regexp::Assemble::_unrev_node(
        { '' => undef, a => [qw[a b]], b => [qw[b c d e f g]] }),
        { '' => undef, b => [qw[b a]], g => [qw[g f e d c b]] },
        'node(*a,b2)' );

    cmp_deeply( Regexp::Assemble::_unrev_node(
        { ab => [qw[ab bc]], bc => [qw[bc cd de ef fg gh]], ef => [qw[ef gh ij]] }),
        { bc => [qw[bc ab]], gh => [qw[gh fg ef de cd bc]], ij => [qw[ij gh ef]] },
        'node(ab,bc,ef)' );

    cmp_deeply( Regexp::Assemble::_unrev_path(
        [qw[ ab cd ef ], {x1 => [qw[x1 y2 z\\d]], mx => [qw[mx us ca]] }], ),
        [{ 'z\\d' => [qw[z\\d y2 x1]], ca => [qw[ca us mx]]}, qw[ef cd ab]], 'path(node)' );

    cmp_deeply( Regexp::Assemble::_unrev_path(
        [qw[a b], {c=>[qw[c d e]], f=>[qw[f g h]], i=>[qw[i j], {k => [qw[k l m]], n=>[qw[n o p]]}, 'x' ]}]),
        [{e=>[qw[e d c]], h=>[qw[h g f]], x=>['x', {m=>[qw[m l k]], p=>[qw[p o n]]}, qw[j i]]}, qw[b a]],
        'path(node(path))');

}
