# 01_insert.t
#
# Test suite for Regexp::Assemble
#
# When a series of paths are inserted in an R::A object, they are
# stored into tree structure using a crafty blend of arrays and hashes.
# 
# These tests verify that the tokens that are added to the
# Regexp::Assemble object are stored correctly.
#
# The tests here verify to a much greater extent that the tree/hash structure
# built up from repeated add() calls produce a structure that the
# subsequent coalescing and reduction routines can operate upon correctly.
#
# copyright (C) 2004-2006 David Landgren

use strict;
use Regexp::Assemble;

use constant permute_testcount => 120 * 5; # permute() has 120 (5!) variants

eval qq{use Test::More tests => 60 + permute_testcount};
if( $@ ) {
    warn "# Test::More not available, no tests performed\n";
    print "1..1\nok 1\n";
    exit 0;
}

my $fixed = 'The scalar remains the same';
$_ = $fixed;

{
    my $ra = Regexp::Assemble->new;
    $ra->insert( '' );
    my $r = ($ra->_path)->[0];
    cmp_ok( ref($r), 'eq', 'HASH',  q{insert('') => first element is a HASH} );
    cmp_ok( scalar(keys %$r), '==', 1,      q{...and contains one key} );
    ok( exists $r->{''},    q{...which is an empty string} );
    ok( !defined($r->{''}), q{...and points to undef} );
}

{
    my $ra = Regexp::Assemble->new;
    $ra->insert( 'a' );
    my $r = $ra->_path;
    cmp_ok( scalar @$r, '==', 1,  q{'a' => path of length 1} );
    cmp_ok( $r->[0], 'eq', 'a',   q{'a' => ...and is an 'a'} );
}

{
    my $r = Regexp::Assemble->new;
    $r->insert();
    $r->insert('a');
    is_deeply( $r->_path, [{'' => undef, 'a' => ['a']}], q{insert(), insert('a')} );
}

{
    my $ra = Regexp::Assemble->new;
    $ra->insert( 'a', 'b' );
    my $r = $ra->_path;
    cmp_ok( scalar @$r, '==', 2,  q{'ab' => path of length 2} );
    cmp_ok( join( '' => @$r ), 'eq', 'ab', q{'ab' => ...and is 'a', 'b'} );
    cmp_ok( $ra->dump, 'eq', '[a b]', 'dump([a b])' );
}

{
    my $ra = Regexp::Assemble->new;
    $ra->insert( 'a', 'b' );
    $ra->insert( 'a', 'c' );
    cmp_ok( $ra->dump, 'eq', '[a {b=>[b] c=>[c]}]', 'dump([a {b c}])' );
    my $r = $ra->_path;
    cmp_ok( scalar @$r, '==', 2,        q{'ab,ac' => path of length 2} );
    cmp_ok( $r->[0], 'eq', 'a',         q{'ab,ac' => ...and first atom is 'a'} );
    cmp_ok( ref($r->[1]), 'eq', 'HASH', q{'ab,ac' => ...and second is a node} );
    $r = $r->[1];
    cmp_ok( scalar(keys %$r), '==', 2,  q{'ab,ac' => ...node has two keys} );
    cmp_ok( join( '' => sort keys %$r ), 'eq', 'bc',
        q{'ab,ac' => ...keys are 'b','c'} );
    ok( exists $r->{b}, q{'ab,ac' => ... key 'b' exists} );
    cmp_ok( ref($r->{b}), 'eq', 'ARRAY', q{'ab,ac' => ... and points to a path} );
    ok( exists $r->{c}, q{'ab,ac' => ... key 'c' exists} );
    cmp_ok( ref($r->{c}), 'eq', 'ARRAY', q{'ab,ac' => ... and points to a path} );
}

{
    my $ra = Regexp::Assemble->new;
    $ra->insert( undef );
    is_deeply( $ra->_path, [{'' => undef}], 'insert(undef)' );
}

{
    my $ra = Regexp::Assemble->new(debug => 1);
    $ra->insert( undef );
    is_deeply( $ra->_path, [{'' => undef}], 'insert(undef)' );
}

{
    my $ra = Regexp::Assemble->new;
    $ra->insert( '' );
    is_deeply( $ra->_path, [{'' => undef}], q{insert('')} );
}

{
    my $r = Regexp::Assemble->new;
    $r->insert();
    is_deeply( $r->_path, [{'' => undef}], 'insert()' );
}

{
    my $ra = Regexp::Assemble->new;
    $ra->insert( '0' );
    is_deeply( $ra->_path,
        [0],
        q{/0/},
    );
}

{
    my $ra = Regexp::Assemble->new;
    $ra->insert( qw/d/ );
    is_deeply( $ra->_path,
        ['d'],
        '/d/',
    );
}

{
    my $r = Regexp::Assemble->new->lex( '\([^(]*(?:\([^)]*\))?[^)]*\)|.' );

    $r->reset->add( 'ab(cd)ef' );
    is_deeply( $r->_path,
        [ 'a', 'b', '(cd)', 'e', 'f' ],
        'ab(cd)ef (with parenthetical lexer)'
    );

    $r->reset->add( 'ab(cd(ef)gh)ij' );
    is_deeply( $r->_path,
        [ 'a', 'b', '(cd(ef)gh)', 'i', 'j' ],
        'ab(cd(ef)gh)ij (with parenthetical lexer)'
    );

    $r->reset->add( 'ab((ef)gh)ij' );
    is_deeply( $r->_path,
        [ 'a', 'b', '((ef)gh)', 'i', 'j' ],
        'ab((ef)gh)ij (with parenthetical lexer)'
    );

    $r->reset->add( 'ab(cd(ef))ij' );
    is_deeply( $r->_path,
        [ 'a', 'b', '(cd(ef))', 'i', 'j' ],
        'ab(cd(ef))ij (with parenthetical lexer)'
    );

    $r->reset->add( 'ab((ef))ij' );
    is_deeply( $r->_path,
        [ 'a', 'b', '((ef))', 'i', 'j' ],
        'ab((ef))ij (with parenthetical lexer)'
    );
}

{
    my $r = Regexp::Assemble->new(lex => '\\d');
    is_deeply( $r->debug(4)->add( '67abc123def+' )->_path,
        [ '6', '7', 'abc', '1', '2', '3', 'def+' ],
        '67abc123def+ with \\d lexer',
    );
    is_deeply( $r->reset->debug(0)->add( '67ab12de+' )->_path,
        [ '6', '7', 'ab', '1', '2', 'de+' ],
        '67ab12de+ with \\d lexer',
    );
}

{
    my $r = Regexp::Assemble->new(lex => '\\d');
    is_deeply( $r->debug(4)->add( '67\\Q1a*\\E12jk' )->_path,
        [ '6', '7', '1', 'a', '\\*', '1', '2', 'jk' ],
        '67\\Q1a*\\E12jk with \\d lexer',
    );
}

{
    my $r = Regexp::Assemble->new(lex => '\\d');
    is_deeply( $r->debug(4)->add( '67\\Q1a*45k+' )->_path,
        [ '6', '7', '1', 'a', '\\*', '4', '5', 'k', '\\+' ],
        '67\\Q1a*45k+ with \\d lexer',
    );
}

{
    my $r = Regexp::Assemble->new(lex => '\\d');
    is_deeply( $r->debug(4)->add( '7\U6a' )->_path,
        [ '7', '6', 'A' ],
        '7\\U6a with \\d lexer',
    );
}

{
    my $r = Regexp::Assemble->new(lex => '\\d');
    is_deeply( $r->debug(4)->add( '8\L9C' )->_path,
        [ '8', '9', 'c' ],
        '8\\L9C with \\d lexer',
    );
}

{
    my $r = Regexp::Assemble->new(lex => '\\d');
    is_deeply( $r->add( '0\Q0C,+' )->_path,
        [ '0', '0', 'C', ',', '\\+' ],
        '0\\Q0C,+ with \\d lexer',
    );
}

{
    my $r = Regexp::Assemble->new(lex => '\\d');
    is_deeply( $r->debug(4)->add( '57\\Q2a+23d+' )->_path,
        [ '5', '7', '2', 'a', '\\+', '2', '3', 'd', '\\+' ],
        '57\\Q2a+23d+ with \\d lexer',
    );
}

{
    my $r = Regexp::Assemble->new(lex => '\\d');
    is_deeply( $r->debug(4)->add( '67\\Uabc\\E123def' )->_path,
        [ '6', '7', '\\Uabc\\E', '1', '2', '3', 'def' ],
        '67\Uabc\\E123def with \\d lexer',
    );
}

{
    my $r = Regexp::Assemble->new(lex => '\\d');
    is_deeply( $r->add( '67\\Q(?:a)?\\E123def' )->_path,
        [ '6', '7', '\\Q(?:a)?\\E', '1', '2', '3', 'def' ],
        '67\Uabc\\E123def with \\d lexer',
    );
}

{
    my $ra = Regexp::Assemble->new;
    $ra->insert( qw/d a b/ );
    is_deeply( $ra->_path,
        [qw/d a b/],
        '/dab/',
    );
}

{
    my $ra = Regexp::Assemble->new;
    $ra->insert( qw/0 1/ );
    $ra->insert( qw/0 2/ );
    is_deeply( $ra->_path,
        [
            '0',
            {
                '1' => ['1'],
                '2' => ['2'],
            },
        ],
        '/01/ /02/',
    );
}

{
    my $ra = Regexp::Assemble->new;
    $ra->insert( qw/0/ );
    $ra->insert( qw/0 1/ );
    $ra->insert( qw/0 2/ );
    is_deeply( $ra->_path,
        [
            '0',
            {
                '1' => ['1'],
                '2' => ['2'],
                ''  => undef,
            },
        ],
        '/0/ /01/ /02/',
    );
}

{
    my $ra = Regexp::Assemble->new;
    $ra->insert( qw/d a m/ );
    $ra->insert( qw/d a m/ );
    is_deeply( $ra->_path,
        [
            'd', 'a', 'm',
        ],
        '/dam/ x 2',
    );
}

{
    my $ra = Regexp::Assemble->new;
    $ra->insert( qw/d a y/ );
    $ra->insert( qw/d a/ );
    $ra->insert( qw/d a/ );
    is_deeply( $ra->_path,
        [
            'd', 'a',
            {
                'y' => ['y'],
                ''  => undef,
            },
        ],
        '/day/, /da/ x 2',
    );
}

{
    my $ra = Regexp::Assemble->new;
    $ra->insert( qw/d o t/ );
    $ra->insert( qw/d o/ );
    $ra->insert( qw/d/ );
    is_deeply( $ra->_path,
        [
            'd',
            {
                'o' => [
                    'o',
                    {
                        't' => ['t'],
                        ''  => undef,
                    },
                ],
                '' => undef,
            },
        ],
        '/dot/ /do/ /d/',
    );
}

{
    my $ra = Regexp::Assemble->new;
    $ra->insert( qw/b i g/ );
    $ra->insert( qw/b i d/ );
    is_deeply( $ra->_path,
        [
            'b', 'i',
            {
                'd' => ['d'],
                'g' => ['g'],
            },
        ],
        '/big/ /bid/',
    );
}

{
    my $ra = Regexp::Assemble->new;
    $ra->insert( qw/d a r t/ );
    $ra->insert( qw/d a m p/ );
    is_deeply( $ra->_path,
        [
            'd', 'a',
            {
                'r' => ['r', 't'],
                'm' => ['m', 'p'],
            },
        ],
        '/dart/ /damp/',
    );
}

{
    my $ra = Regexp::Assemble->new;
    $ra->insert( qw/a m b l e/ );
    $ra->insert( qw/i d l e/ );
    is_deeply( $ra->_path,
        [
            {
                'a' => ['a', 'm', 'b', 'l', 'e'],
                'i' => ['i', 'd', 'l', 'e'],
            },
        ],
        '/amble/ /idle/',
    );
}

{
    my $ra = Regexp::Assemble->new;
    $ra->insert( qw/a m b l e/ );
    $ra->insert( qw/a m p l e/ );
    $ra->insert( qw/i d l e/ );
    is_deeply( $ra->_path,
        [
            {
                'a' => [
                    'a', 'm',
                    {
                        'b' => [ 'b', 'l', 'e' ],
                        'p' => [ 'p', 'l', 'e' ],
                    },
                ],
                'i' => ['i', 'd', 'l', 'e'],
            },
        ],
        '/amble/ /ample/ /idle/',
    );
}

{
    my $ra = Regexp::Assemble->new;
    $ra->insert( qw/d a m/ );
    $ra->insert( qw/d a r e/ );
    is_deeply( $ra->_path,
        [
            'd', 'a',
            {
                'm' => ['m'],
                'r' => ['r', 'e'],
                    ,
            },
        ],
        '/dam/ /dare/',
    );
}

{
    my $ra = Regexp::Assemble->new
        ->insert(qw/d a/)
        ->insert(qw/d b/)
        ->insert(qw/d c/)
    ;
    is_deeply( $ra->_path,
        [
            'd',
            {
                'a' => ['a'],
                'b' => ['b'],
                'c' => ['c'],
            },
        ],
        '/da/ /db/ /dc/',
    );
}

{
    my $ra = Regexp::Assemble->new
        ->insert(qw/d a/)
        ->insert(qw/d b c d/)
        ->insert(qw/d c/)
    ;
    is_deeply( $ra->_path,
        [
            'd',
            {
                'a' => ['a'],
                'b' => ['b', 'c', 'd'],
                'c' => ['c'],
            },
        ],
        '/da/ /dbcd/ /dc/',
    );
}

sub permute {
    my $target = shift;
    my $path   = shift;
    my( $x1, $x2, $x3, $x4, $x5 );
    for $x1( 0..4 ) {
        for $x2( 0..4 ) {
            next if $x2 == $x1;
            for $x3( 0..4 ) {
                next if grep { $_ == $x3 } ($x1, $x2);
                for $x4( 0..4 ) {
                    next if grep { $_ == $x4 } ($x1, $x2, $x3);
                    for $x5( 0..4 ) {
                        next if grep { $_ == $x5 } ($x1, $x2, $x3, $x4);
                        my $ra = Regexp::Assemble->new
                            ->insert( @{$path->[$x1]} )
                            ->insert( @{$path->[$x2]} )
                            ->insert( @{$path->[$x3]} )
                            ->insert( @{$path->[$x4]} )
                            ->insert( @{$path->[$x5]} )
                        ;
                        is_deeply( $ra->_path, $target,
                            '/' . join( '/ /', 
                                join( '' => @{$path->[$x1]}),
                                join( '' => @{$path->[$x2]}),
                                join( '' => @{$path->[$x3]}),
                                join( '' => @{$path->[$x4]}),
                                join( '' => @{$path->[$x5]}),
                            ) . '/'
                        ) or diag(
                            $ra->dump(),
                            ' versus ',
                            Regexp::Assemble->_dump($target),
                            "\n",
                        );
                    }
                }
            }
        }
    }
}

permute(
    [
        'a', {
            '' => undef, 'b' => [
                'b', {
                    '' => undef, 'c' => [
                        'c', {
                            '' => undef, 'd' => [
                                'd', {
                                    '' => undef, 'e' => [
                                        'e',
                                    ],
                                },
                            ],
                        },
                    ],
                },
            ],
        },
    ],
    [
        [ 'a',                    ],
        [ 'a', 'b'                ],
        [ 'a', 'b', 'c'           ],
        [ 'a', 'b', 'c', 'd'      ],
        [ 'a', 'b', 'c', 'd', 'e' ],
    ]
);

permute(
    [
        {
            '' => undef, 'a' => [
                'a', {
                    '' => undef, 'b' => [
                        'b', {
                            '' => undef, 'c' => [
                                'c', {
                                    '' => undef, 'd' => [
                                        'd',
                                    ],
                                },
                            ],
                        },
                    ],
                },
            ],
        },
    ],
    [
        [ '',                ],
        [ 'a',               ],
        [ 'a', 'b'           ],
        [ 'a', 'b', 'c'      ],
        [ 'a', 'b', 'c', 'd' ],
    ]
);

permute(
    [ 'd', 'o',
    {
        'n' => [
            'n', 'a', 't',
            {
                'e' => ['e'],
                'i' => ['i', 'o', 'n'],
            },
        ]
        ,
        't' => [
            't',
            {
                'a' => ['a', 't', 'e'],
                'i' => ['i', 'n', 'g'],
            },
        ],
        ,
        '' => undef,
    }],
    [
        [ split //, 'do'       ],
        [ split //, 'donate'   ],
        [ split //, 'donation' ],
        [ split //, 'dotate'   ],
        [ split //, 'doting'   ],
    ]
);

permute(
    [
        'o',
        {
            ''  => undef,
            'n' => [
                'n', {
                    ''  => undef,
                    'l' => ['l', 'y'],
                    'e' => [
                        'e', {
                            ''  => undef,
                            'r' => ['r'],
                        }
                    ],
                },
            ],
        },
    ],
    [
        [ split //, 'o'    ],
        [ split //, 'on'   ],
        [ split //, 'one'  ],
        [ split //, 'only' ],
        [ split //, 'oner' ],
    ],
);

permute(
    [
        'a', 'm',
        {
            'a' => [ 'a',
                {
                    's' => ['s', 's'],
                    'z' => ['z', 'e'],
                },
            ],
            'u' => [ 'u',
                {
                    'c' => ['c', 'k'],
                    's' => ['s', 'e'],
                }
            ],
            'b' => [ 'b', 'l', 'e' ],
        },
    ],
    [
        [ split //, 'amass' ],
        [ split //, 'amaze' ],
        [ split //, 'amble' ],
        [ split //, 'amuck' ],
        [ split //, 'amuse' ],
    ],
);

Regexp::Assemble::Default_Lexer( '\([^(]*(?:\([^)]*\))?[^)]*\)|.' );

{
    my $r = Regexp::Assemble->new;

    $r->reset->add( 'ab(cd)ef' );
    is_deeply( $r->_path,
        [ 'a', 'b', '(cd)', 'e', 'f' ],
        'ab(cd)ef (with Default parenthetical lexer)'
    );

    $r->reset->add( 'ab((ef)gh)ij' );
    is_deeply( $r->_path,
        [ 'a', 'b', '((ef)gh)', 'i', 'j' ],
        'ab((ef)gh)ij (with Default parenthetical lexer)'
    );

    $r->reset->add( 'ab(ef(gh))ij' );
    is_deeply( $r->_path,
        [ 'a', 'b', '(ef(gh))', 'i', 'j' ],
        'ab(ef(gh))ij (with Default parenthetical lexer)'
    );

    eval { $r->filter('choke') };
    ok( $@, 'die on non-CODE filter' );

    eval { $r->pre_filter('choke') };
    ok( $@, 'die on non-CODE pre_filter' );
}

cmp_ok( $_, 'eq', $fixed, '$_ has not been altered' );
