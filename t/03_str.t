# 03_str.t
#
# Test suite for Regexp::Assemble
# Ensure the the generated patterns seem reasonable.
#
# copyright (C) 2004-2005 David Landgren

use strict;

eval qq{use Test::More tests => 134};
if( $@ ) {
    warn "# Test::More not available, no tests performed\n";
    print "1..1\nok 1\n";
    exit 0;
}

use Regexp::Assemble;

my $fixed = 'The scalar remains the same';
$_ = $fixed;

cmp_ok( Regexp::Assemble->new->as_string, 'eq', '^a\bz', 'empty' );

cmp_ok( Regexp::Assemble->new
    ->insert( '' )
    ->as_string, 'eq', '(?:)?', '//' );

cmp_ok( Regexp::Assemble->new
    ->insert( 'd' )
    ->as_string, 'eq', 'd', '/d/' );

cmp_ok( Regexp::Assemble->new
    ->insert( 'd', 'o', 't' )
    ->as_string, 'eq', 'dot', 'd o t' );

cmp_ok( Regexp::Assemble->new
    ->insert( 'd' )
    ->insert( 'o' )
    ->insert( 't' )
    ->as_string, 'eq', '[dot]', '/d/ /o/ /t/' );

cmp_ok( Regexp::Assemble->new
    ->insert( 'd' )
    ->insert( '' )
    ->as_string, 'eq', 'd?', '// /d/' );

cmp_ok( Regexp::Assemble->new
    ->insert( 'd', 'a' )
    ->as_string, 'eq', 'da', '/da/' );

cmp_ok( Regexp::Assemble->new
    ->insert( 'd' )
    ->insert( 'd', 'a' )
    ->as_string, 'eq', 'da?', '/d/ /da/' );

cmp_ok( Regexp::Assemble->new
    ->insert( '' )
    ->insert( 'd', 'a' )
    ->as_string, 'eq', '(?:da)?', '// /da/' );

cmp_ok( Regexp::Assemble->new
    ->insert( '' )
    ->insert( 'a' )
    ->insert( 'd' )
    ->as_string, 'eq', '[ad]?', '// /a/ /d/' );

cmp_ok( Regexp::Assemble->new
    ->insert( '' )
    ->insert( 'a' )
    ->insert( 'd', 'o' )
    ->as_string, 'eq', '(?:do|a)?', '// /a/ /do/' );

cmp_ok( Regexp::Assemble->new
    ->insert( 'x' )
    ->insert( '.' )
    ->as_string, 'eq', '.', '/x/ /./' );

cmp_ok( Regexp::Assemble->new
    ->insert( '\033' )
    ->insert( '.' )
    ->as_string, 'eq', '.', '/\x033/ /./' );

cmp_ok( Regexp::Assemble->new
    ->insert( '\\d' )
    ->insert( '\\s' )
    ->insert( '.' )
    ->as_string, 'eq', '.', '/\d/ /\s/ /./' );

cmp_ok( Regexp::Assemble->new
    ->insert( '\\d' )
    ->insert( '\\D' )
    ->as_string, 'eq', '.', '/\d/ /\D/' );

cmp_ok( Regexp::Assemble->new
    ->insert( '\\s' )
    ->insert( '\\S' )
    ->as_string, 'eq', '.', '/\s/ /\S/' );

cmp_ok( Regexp::Assemble->new
    ->insert( '\\w' )
    ->insert( '\\W' )
    ->as_string, 'eq', '.', '/\w/ /\W/' );

cmp_ok( Regexp::Assemble->new
    ->insert( '\\w' )
    ->insert( '\\W' )
    ->insert( "\t" )
    ->as_string, 'eq', '.', '/\w/ /\W/ /\t/' );

cmp_ok( Regexp::Assemble->new
    ->insert( '\\d' )
    ->insert( '5' )
    ->as_string, 'eq', '\\d', '/\d/ /5/' );

cmp_ok( Regexp::Assemble->new
    ->insert( '\\d' )
    ->insert( '5' )
    ->insert( '' )
    ->as_string, 'eq', '\\d?', '/\d/ /5/ //' );

cmp_ok( Regexp::Assemble->new
    ->insert( '\\s' )
    ->insert( ' ' )
    ->as_string, 'eq', '\\s', '/\s/ / /' );

cmp_ok( Regexp::Assemble->new
    ->insert( '\\s' )
    ->insert( '' )
    ->as_string, 'eq', '\\s?', '/\s/ //' );

cmp_ok( Regexp::Assemble->new
    ->insert( '\\d' )
    ->insert( '5' )
    ->insert( '7' )
    ->insert( '0' )
    ->as_string, 'eq', '\\d', '/\d/ /0/ /5/ /7/' );

cmp_ok( Regexp::Assemble->new
    ->insert( '\\d' )
    ->insert( 'x' )
    ->insert( '5' )
    ->insert( '7' )
    ->insert( '0' )
    ->as_string, 'eq', '[\\dx]', '/\d/ /x/ /0/ /5/ /7/' );

cmp_ok( Regexp::Assemble->new
    ->insert( '\\d' )
    ->insert( '\\s' )
    ->insert( ' ' )
    ->insert( '5' )
    ->insert( '7' )
    ->insert( '0' )
    ->as_string, 'eq', '[\\d\\s]', '/\d/ /\s/ / / /0/ /5/ /7/' );

cmp_ok( Regexp::Assemble->new
    ->insert( '\\.' )
    ->insert( 'p' )
    ->as_string, 'eq', '[.p]', '/\./ /p/' );

cmp_ok( Regexp::Assemble->new
    ->insert( '\\w' )
    ->insert( '5' )
    ->insert( '1' )
    ->insert( '0' )
    ->insert( 'a' )
    ->insert( '_' )
    ->as_string, 'eq', '\\w', '/\w/ /_/ /a/ /0/ /5/ /1/' );

cmp_ok( Regexp::Assemble->new
    ->insert( '\\d' )
    ->insert( '\\^' )
    ->insert( '' )
    ->as_string, 'eq', '[\\d^]?', '/\d/ /^/ //' );

cmp_ok( Regexp::Assemble->new
    ->insert( '\\d' )
    ->insert( '\\^' )
    ->insert( '' )
    ->as_string, 'eq', '[\\d^]?', '/\d/ /^/ //' );

cmp_ok( Regexp::Assemble->new
    ->insert( 'a', "\@", 'z' )
    ->insert( 'a', "\?", 'z' )
    ->as_string, 'eq', 'a[?@]z', '/a\@z/ /a\?z/' );

cmp_ok( Regexp::Assemble->new
    ->insert( '\\+' )
    ->as_string, 'eq', '\\+', '/\+/' );

cmp_ok( Regexp::Assemble->new
    ->insert( quotemeta '+' )
    ->as_string, 'eq', '\\+', 'quotemeta +' );

cmp_ok( Regexp::Assemble->new
    ->insert( '\\+' )
    ->insert( '\\*' )
    ->as_string, 'eq', '[*+]', '/\+/ /\*/' );

cmp_ok( Regexp::Assemble->new
    ->insert( quotemeta '+' )
    ->insert( quotemeta '*' )
    ->as_string, 'eq', '[*+]', 'quotemeta + *' );

cmp_ok( Regexp::Assemble->new
    ->insert( '-' )
    ->insert( 'z' )
    ->insert( '0' )
    ->as_string, 'eq', '[-0z]', '/-/ /0/ /z/' );

cmp_ok( Regexp::Assemble->new
    ->insert( '-' )
    ->insert( '\\.' )
    ->insert( '0' )
    ->as_string, 'eq', '[-.0]', '/-/ /./ /0/' );

cmp_ok( Regexp::Assemble->new
    ->insert( '-' )
    ->insert( '\\+' )
    ->insert( '\\*' )
    ->as_string, 'eq', '[-*+]', '/-/ /\+/ /\*/' );

cmp_ok( Regexp::Assemble->new
    ->insert( '\.' )
    ->insert( '-' )
    ->as_string, 'eq', '[-.]', '/\./ /-/' );

cmp_ok( Regexp::Assemble->new
    ->insert( '^' )
    ->insert( 'z' )
    ->insert( '0' )
    ->as_string, 'eq', '(?:[0z]|^)', '/^/ /0/ /z/' );

cmp_ok( Regexp::Assemble->new
    ->insert( '^' )
    ->insert( 'z' )
    ->insert( '-' )
    ->insert( '0' )
    ->as_string, 'eq', '(?:[-0z]|^)', '/^/ /-/ /0/ /z/' );

cmp_ok( Regexp::Assemble->new
    ->insert( '^' )
    ->insert( '\w' )
    ->insert( 'z' ) # z and 0 absorbed by \w
    ->insert( '-' )
    ->insert( '0' )
    ->as_string, 'eq', '(?:[-\w]|^)', '/^/ /-/ /0/ /\w/ /z/' );

cmp_ok( Regexp::Assemble->new
    ->insert( '$' )
    ->insert( '-' )
    ->insert( '0' )
    ->as_string, 'eq', '(?:[-0]|$)', '/$/ /-/ /0/' );

{
    my $re = Regexp::Assemble->new->add( 'de' )->re;
    cmp_ok( "$re", 'eq', '(?-xism:de)', 'de' );
}

{
    my $re = Regexp::Assemble->new
        ->add( '^a' )
        ->add( 'ma' )
        ->re;
    cmp_ok( "$re", 'eq', '(?-xism:(?:^|m)a)', '^a, ma' );
}

{
    my $re = Regexp::Assemble->new
        ->add( '^a' )
        ->add( 'ma' )
        ->add( 'wa' )
        ->re;
    cmp_ok( $re, 'eq', '(?-xism:(?:[mw]|^)a)', '^a, ma, wa' );
}

{
    my $re = Regexp::Assemble->new
        ->add( '^a' )
        ->add( '\\^a' )
        ->re;
    cmp_ok( $re, 'eq', '(?-xism:(?:^|\\^)a)', '^a, \\^a' );
}

{
    my $re = Regexp::Assemble->new
        ->add( '^a' )
        ->add( '0a' )
        ->re;
    cmp_ok( $re, 'eq', '(?-xism:(?:^|0)a)', '^a, 0a' );
}

{
    my $re = Regexp::Assemble->new
        ->add( '^a' )
        ->add( '\\^a' )
        ->add( 'ma' )
        ->re;
    cmp_ok( $re, 'eq', '(?-xism:(?:[m^]|^)a)', '^a, \\^a, ma' );
}

{
    my $re = Regexp::Assemble->new
        ->add( '^a' )
        ->add( 'maa' )
        ->re;
    cmp_ok( $re, 'eq', '(?-xism:(?:ma|^)a)', '^a, maa' );
}

{
    my $re = Regexp::Assemble->new
        ->add( 'b$' )
        ->add( 'be' )
        ->re;
    cmp_ok( $re, 'eq', '(?-xism:b(?:$|e))', 'b$, be' );
}

{
    my $re = Regexp::Assemble->new
        ->add( 'b$' )
        ->add( 'be' )
        ->add( 'ba' )
        ->re;
    cmp_ok( $re, 'eq', '(?-xism:b(?:[ae]|$))', 'b$, be' );
}

{
    my $re = Regexp::Assemble->new
        ->add( 'b$' )
        ->add( 'b\$' )
        ->re;
    cmp_ok( $re, 'eq', '(?-xism:b(?:$|\\$))', 'b$, b\\$' );
}

{
    my $re = Regexp::Assemble->new
        ->add( '^ab' )
        ->add( '^ac' )
        ->add( 'de' )
        ->re;
    cmp_ok( $re, 'eq', '(?-xism:(?:^a[bc]|de))', 'ab, ac, de' );
}

{
    my $re = Regexp::Assemble->new( flags => 'i' )
        ->add( '^ab' )
        ->add( '^ac' )
        ->add( 'de' )
        ->re;
    cmp_ok( $re, 'eq', '(?-xism:(?i:(?:^a[bc]|de)))', 'ab, ac, de /i' );
}

cmp_ok( Regexp::Assemble->new
    ->add( quotemeta( 'a%d' ))
    ->add( quotemeta( 'a=b' ))
    ->add( quotemeta( 'a%e' ))
    ->add( quotemeta( 'a=c' ))
    ->as_string, 'eq', 'a(?:%[de]|=[bc])'
);

cmp_ok( Regexp::Assemble->new
    ->add( quotemeta( '^:' ))
    ->add( quotemeta( '^,' ))
    ->as_string, 'eq', '\\^[,:]'
);

cmp_ok( Regexp::Assemble->new
    ->add( quotemeta( 'a=' ))
    ->add( quotemeta( 'a*' ))
    ->add( quotemeta( 'a-' ))
    ->as_string, 'eq', 'a[-*=]'
);

cmp_ok( Regexp::Assemble->new
    ->insert( '0' )
    ->insert( '1' )
    ->insert( '2' )
    ->insert( '3' )
    ->insert( '4' )
    ->insert( '5' )
    ->insert( '6' )
    ->insert( '7' )
    ->insert( '8' )
    ->insert( '9' )
    ->as_string, 'eq', '\\d', '/0/ .. /9/' );

cmp_ok( Regexp::Assemble->new
    ->insert( 'x' )
    ->insert( '0' )
    ->insert( '1' )
    ->insert( '2' )
    ->insert( '3' )
    ->insert( '4' )
    ->insert( '5' )
    ->insert( '6' )
    ->insert( '7' )
    ->insert( '8' )
    ->insert( '9' )
    ->as_string, 'eq', '[\\dx]', '/0/ .. /9/ /x/' );

cmp_ok( Regexp::Assemble->new
    ->insert( '' )
    ->insert( 'b', 'e' )
    ->insert( 'b', 'y' )
    ->as_string, 'eq', '(?:b[ey])?', '// /be/ /by/' );

cmp_ok( Regexp::Assemble->new
    ->insert( '' )
    ->insert( 'b', 'e' )
    ->insert( 'd', 'o' )
    ->as_string, 'eq', '(?:be|do)?', '// /be/ /do/' );

cmp_ok( Regexp::Assemble->new
    ->insert( '' )
    ->insert( 'a' )
    ->insert( 'b', 'e' )
    ->insert( 'b', 'y' )
    ->as_string, 'eq', '(?:b[ey]|a)?', '// /a/ /be/ /by/' );

cmp_ok( Regexp::Assemble->new
    ->insert( 'd', 'a', 'b' )
    ->insert( 'd', 'a', 'y' )
    ->as_string, 'eq', 'da[by]', '/dab/ /day/' );

cmp_ok( Regexp::Assemble->new
    ->insert( 'd', 'a', 'b' )
    ->insert( 'd', 'a', 'i', 'l', 'y' )
    ->as_string, 'eq', 'da(?:ily|b)', '/dab/ /daily/' );

cmp_ok( Regexp::Assemble->new
    ->insert( 'd', 'a', 'b' )
    ->insert( 'd', 'a', 'y' )
    ->insert( 'd', 'a', 'i', 'l', 'y' )
    ->as_string, 'eq', 'da(?:(?:il)?y|b)', '/dab/ /day/ /daily/' );

cmp_ok( Regexp::Assemble->new
    ->insert( 'd', 'a', 'b' )
    ->insert( 'd', 'a', 'b', 'b', 'l', 'e' )
    ->as_string, 'eq', 'dab(?:ble)?', '/dab/ /dabble/' );

cmp_ok( Regexp::Assemble->new
    ->insert( 'd', 'o', 'b' )
    ->insert( 'd', 'o', 'e' )
    ->insert( 'd', 'o', 'g' )
    ->insert( 'd', 'o', 'n' )
    ->insert( 'd', 'o', 't' )
    ->insert( 'd', 'u', 'b' )
    ->insert( 'd', 'u', 'd' )
    ->as_string, 'eq', 'd(?:o[begnt]|u[bd])', '/dob/ /doe/ /dog/ /don/ /dot/ /dub/ /dud/' );

cmp_ok( Regexp::Assemble->new
    ->insert( 'd' )
    ->insert( 'd', 'o' )
    ->insert( 'd', 'o', 'n' )
    ->insert( 'd', 'o', 'n', 'e' )
    ->as_string, 'eq', 'd(?:o(?:ne?)?)?', '/d/ /do/ /don/ /done/' );

cmp_ok( Regexp::Assemble->new
    ->insert( '' )
    ->insert( 'd' )
    ->insert( 'd', 'o' )
    ->insert( 'd', 'o', 'n' )
    ->insert( 'd', 'o', 'n', 'e' )
    ->as_string, 'eq', '(?:d(?:o(?:ne?)?)?)?', '// /d/ /do/ /don/ /done/' );

cmp_ok( Regexp::Assemble->new
    ->insert( 'd', 'a', 'y' )
    ->insert( 'n', 'i', 'g', 'h', 't' )
    ->as_string, 'eq', '(?:night|day)', '/day/ /night/' );

cmp_ok( Regexp::Assemble->new
    ->insert( 'd', 'a', 'm', 'p' )
    ->insert( 'd', 'a', 'm', 'e' )
    ->insert( 'd', 'a', 'r', 't' )
    ->insert( 'd', 'a', 'r', 'k' )
    ->as_string, 'eq', 'da(?:m[ep]|r[kt])', '/dame/ /damp/ /dark/ /dart/' );

cmp_ok( Regexp::Assemble->new
    ->add( qw/ lit limit / )
    ->as_string, 'eq', 'l(?:im)?it', '/lit limit/'
);

cmp_ok( Regexp::Assemble->new
    ->add( qw/ amz adnz aenz agrwz agqwz ahwz / )
    ->as_string, 'eq', 'a(?:(?:g[qr]|h)w|[de]n|m)z', 'amz adnz aenz agrwz agqwz ahwz' );

cmp_ok( Regexp::Assemble->new
    ->add( qw/adktwz aeftwz aeguwz aehuwz afwz agmvz ahnvz aijmvz/ )
    ->as_string, 'eq', 'a(?:(?:e(?:[gh]u|ft)|dkt|f)w|(?:(?:ij|g)m|hn)v)z',
    'adktwz aeftwz aeguwz aehuwz afwz agmvz ahnvz aijmvz' );

cmp_ok( Regexp::Assemble->new
    ->add( qw/bcktx bckx bdix bdktx bdkx/ )
    ->as_string, 'eq', 'b(?:d(?:kt?|i)|ckt?)x', 'bcktx bckx bdix bdktx bdkx' );

cmp_ok( Regexp::Assemble->new
    ->add( qw/ dldrt dndrt dldt dndt dx / )
    ->as_string, 'eq', 'd(?:[ln]dr?t|x)', 'dldrt dndrt dldt dndt dx' );

cmp_ok( Regexp::Assemble->new
    ->add( qw/ dldt dndt dlpt dnpt dx / )
    ->as_string, 'eq', 'd(?:[ln][dp]t|x)', q/ dldt dndt dlpt dnpt dx / );

cmp_ok( Regexp::Assemble->new
    ->add( qw/ dldrt dndrt dldmt dndmt dlprt dnprt dlpmt dnpmt dx / )
    ->as_string, 'eq', 'd(?:[ln][dp][mr]t|x)',
    'dldrt dndrt dldmt dndmt dlprt dnprt dlpmt dnpmt dx' );

# note: \d+ does not (currently) absorb 7
cmp_ok( Regexp::Assemble->new
    ->add( qw/ abz acdez a5txz a7z /, 'a\\d+z', 'a\\d+-\\d+z' ) # 5.6.0 kluge
    ->as_string, 'eq', 'a(?:[7b]|(?:\d+-)?\d+|5tx|cde)z',
    'abz a\\d+z acdez a\\d+-\\d+z a5txz a7z' );

cmp_ok( Regexp::Assemble->new
    ->add( '\\*mens', '\\(scan', '\\[mail' )
    ->as_string, 'eq', '(?:\(scan|\*mens|\[mail)',
    '\\*mens \\(scan \\[mail' );

cmp_ok( Regexp::Assemble->new
    ->add( '\Qa[b[c' )
    ->as_string, 'eq', 'a\[b\[c',
    'a[b[c' );

cmp_ok( Regexp::Assemble->new
    ->add( '\Qa]b]c' )
    ->as_string, 'eq', 'a\]b\]c',
    'a]b]c' );

cmp_ok( Regexp::Assemble->new
    ->add( '\Qa(b(c' )
    ->as_string, 'eq', 'a\(b\(c',
    'a(b(c' );

cmp_ok( Regexp::Assemble->new
    ->add( '\Qa)b)c' )
    ->as_string, 'eq', 'a\)b\)c',
    'a)b)c' );

cmp_ok( Regexp::Assemble->new
    ->add( '\Qa(b' )
    ->add( '\Qa[b' )
    ->add( '\Qa+b' )
    ->as_string, 'eq', 'a[(+[]b',
    'a(b a[b a+b' );

cmp_ok( Regexp::Assemble->new
    ->add( '\Qa^b' )
    ->add( '\Qa-b' )
    ->add( '\Qa+b' )
    ->as_string, 'eq', 'a[-+^]b',
    'a^b a-b a+b' );

my $mute = Regexp::Assemble->new->mutable(1);

$mute->add( 'dog' );
cmp_ok( $mute->as_string, 'eq', 'dog', 'mute dog' );
cmp_ok( $mute->as_string, 'eq', 'dog', 'mute dog cached' );

$mute->add( 'dig' );
cmp_ok( $mute->as_string, 'eq', 'd(?:ig|og)', 'mute dog' );

my $red = Regexp::Assemble->new->reduce(0);

$red->add( 'dog' );
$red->add( 'dig' );
cmp_ok( $red->as_string, 'eq', 'd(?:ig|og)', 'mute dig dog' );

$red->add( 'dog' );
cmp_ok( $red->as_string, 'eq', 'dog', 'mute dog 2' );

$red->add( 'dig' );
cmp_ok( $red->as_string, 'eq', 'dig', 'mute dig 2' );

cmp_ok( Regexp::Assemble->new
    ->add( qw/ dldrt dndrt dldt dndt dx / )
    ->as_string(indent => 3),
'eq',
'd
(?:
   [ln]dr?t
   |x
)'
,  'dldrt dndrt dldt dndt dx (indent 3)' );

cmp_ok( Regexp::Assemble->new( indent => 2 )
    ->add( qw/foo bar/ )
    ->as_string,
'eq',
'(?:
  bar
  |foo
)'
, 'pretty foo bar' );

cmp_ok( Regexp::Assemble->new
    ->indent(2)
    ->add( qw/food fool bar/ )
    ->as_string,
'eq',
'(?:
  foo[dl]
  |bar
)'
, 'pretty food fool bar' );

cmp_ok( Regexp::Assemble->new
    ->add( qw/afood afool abar/ )
    ->indent(2)
    ->as_string,
'eq',
'a
(?:
  foo[dl]
  |bar
)'
, 'pretty afood afool abar' );

cmp_ok( Regexp::Assemble->new
    ->add( qw/dab dam day/ )
    ->as_string(indent => 2),
'eq', 'da[bmy]', 'pretty dab dam day' );

cmp_ok( Regexp::Assemble->new(indent => 5)
    ->add( qw/be bed/ )
    ->as_string(indent => 2),
'eq', 'bed?'
, 'pretty be bed' );

cmp_ok( Regexp::Assemble->new(indent => 5)
    ->add( qw/b-d b\.d/ )
    ->as_string(indent => 2),
'eq', 'b[-.]d'
, 'pretty b-d b\.d' );

cmp_ok( Regexp::Assemble->new
    ->add( qw/be bed beg bet / )
    ->as_string(indent => 2),
'eq', 'be[dgt]?'
, 'pretty be bed beg bet' );

cmp_ok( Regexp::Assemble->new
    ->add( qw/afoodle afoole abarle/ )
    ->as_string(indent => 2),
'eq',
'a
(?:
  food?
  |bar
)
le'
, 'pretty afoodle afoole abarle' );

cmp_ok( Regexp::Assemble->new
    ->add( qw/afar afoul abate aback/ )
    ->as_string(indent => 2),
'eq',
'a
(?:
  ba
  (?:
    ck
    |te
  )
  |f
  (?:
    oul
    |ar
  )
)'
, 'pretty pretty afar afoul abate aback' );


cmp_ok( Regexp::Assemble->new
    ->add( qw/stormboy steamboy saltboy sockboy/ )
    ->as_string(indent => 5),
'eq',
's
(?:
     t
     (?:
          ea
          |or
     )
     m
     |alt
     |ock
)
boy'
, 'pretty stormboy steamboy saltboy sockboy' );

cmp_ok( Regexp::Assemble->new
    ->add( qw/stormboy steamboy stormyboy steamyboy saltboy sockboy/ )
    ->as_string(indent => 4),
'eq',
's
(?:
    t
    (?:
        ea
        |or
    )
    my?
    |alt
    |ock
)
boy'
, 'pretty stormboy steamboy stormyboy steamyboy saltboy sockboy' );

cmp_ok( Regexp::Assemble->new
    ->add( qw/stormboy steamboy stormyboy steamyboy stormierboy steamierboy saltboy/ )
    ->as_string(indent => 1),
'eq',
's
(?:
 t
 (?:
  ea
  |or
 )
 m
 (?:
  ier
  |y
 )
 ?
 |alt
)
boy'
, 'pretty stormboy steamboy stormyboy steamyboy stormierboy steamierboy saltboy' );

cmp_ok( Regexp::Assemble->new
    ->add( qw/showerless showeriness showless showiness show shows/ )
    ->as_string(indent => 4), 'eq',
'show
(?:
    (?:
        (?:
            er
        )
        ?
        (?:
            in
            |l
        )
        es
    )
    ?s
)
?' , 'pretty showerless showeriness showless showiness show shows' );

cmp_ok( Regexp::Assemble->new->add( qw/
    showerless showeriness showdeless showdeiness showless showiness show shows
    / )->as_string(indent => 4), 'eq',
'show
(?:
    (?:
        (?:
            de
            |er
        )
        ?
        (?:
            in
            |l
        )
        es
    )
    ?s
)
?' , 'pretty showerless showeriness showdeless showdeiness showless showiness show shows' );

cmp_ok( Regexp::Assemble->new->add( qw/
        convenient consort concert
    / )->as_string(indent => 4), 'eq',
'con
(?:
    (?:
        ce
        |so
    )
    r
    |venien
)
t', 'pretty convenient consort concert' );

cmp_ok( Regexp::Assemble->new->add( qw/
        200.1 202.1 207.4 208.3 213.2
    / )->as_string(indent => 4), 'eq',
'2
(?:
    0
    (?:
        [02].1
        |7.4
        |8.3
    )
    |13.2
)', 'pretty 200.1 202.1 207.4 208.3 213.2' );


cmp_ok( Regexp::Assemble->new->add( qw/
        yammail\.com yanmail\.com yeah\.net yourhghorder\.com yourload\.com
    / )->as_string(indent => 4),
'eq',
'y
(?:
    (?:
        our
        (?:
            hghorder
            |load
        )
        |a[mn]mail
    )
    \.com
    |eah\.net
)'
, 'pretty yammail.com yanmail.com yeah.net yourhghorder.com yourload.com' );

cmp_ok( Regexp::Assemble->new->debug(1)->add( qw/
        0\.0 0\.2 0\.7 0\.01 0\.003
    / )->as_string(indent => 4),
'eq',
'0\.
(?:
    0
    (?:
        03
        |1
    )
    ?
    |[27]
)'
, 'pretty 0.0 0.2 0.7 0.01 0.003' );

cmp_ok( Regexp::Assemble->new->add( qw/
        convenient containment consort concert
    / )->as_string(indent => 4),
'eq',
'con
(?:
    (?:
        tainm
        |veni
    )
    en
    |
    (?:
        ce
        |so
    )
    r
)
t'
, 'pretty convenient containment consort concert' );

cmp_ok( Regexp::Assemble->new->add( qw/
        sat sit bat bit sad sid bad bid
    / )->as_string(indent => 5),
'eq',
'(?:
     b
     (?:
          a[dt]
          |i[dt]
     )
     |s
     (?:
          a[dt]
          |i[dt]
     )
)'
, 'pretty sat sit bat bit sad sid bad bid' );

cmp_ok( Regexp::Assemble->new->add( qw/
        commercial\.net compuserve\.com compuserve\.net concentric\.net
        coolmail\.com coventry\.com cox\.net
    / )->as_string(indent => 5),
'eq',
'co
(?:
     m
     (?:
          puserve\.
          (?:
               com
               |net
          )
          |mercial\.net
     )
     |
     (?:
          olmail
          |ventry
     )
     \.com
     |
     (?:
          ncentric
          |x
     )
     \.net
)'
, 'pretty c*.*' );

cmp_ok( Regexp::Assemble->new->add( qw/
        ambient\.at agilent\.com americanexpress\.com amnestymail\.com
        amuromail\.com angelfire\.com anya\.com anyi\.com aol\.com
        aolmail\.com artfiles\.de arcada\.fi att\.net
    / )->as_string(indent => 5), 'eq',
'a
(?:
     m
     (?:
          (?:
               (?:
                    nesty
                    |uro
               )
               mail
               |ericanexpress
          )
          \.com
          |bient\.at
     )
     |
     (?:
          n
          (?:
               gelfire
               |y[ai]
          )
          |o
          (?:
               lmai
          )
          ?l
          |gilent
     )
     \.com
     |r
     (?:
          tfiles\.de
          |cada\.fi
     )
     |tt\.net
)' , 'pretty a*.*' );

cmp_ok( Regexp::Assemble->new->add( qw/
    looked choked hooked stoked toked baked faked
    / )->as_string(indent => 4), 'eq',
'(?:
    (?:
        [hl]o
        |s?t
        |ch
    )
    o
    |[bf]a
)
ked' , 'looked choked hooked stoked toked baked faked' );

cmp_ok( Regexp::Assemble->new->add( qw/
arson bison brickmason caisson comparison crimson diapason disimprison empoison
foison foreseason freemason godson grandson impoison imprison jettison lesson
liaison mason meson midseason nonperson outreason parson person poison postseason
precomparison preseason prison reason recomparison reimprison salesperson samson
season stepgrandson stepson stonemason tradesperson treason unison venison vison
whoreson
    / )->as_string(indent => 4), 'eq',
'(?:
    p
    (?:
        r
        (?:
            e
            (?:
                compari
                |sea
            )
            |i
        )
        |o
        (?:
            stsea
            |i
        )
        |[ae]r
    )
    |s
    (?:
        t
        (?:
            ep
            (?:
                grand
            )
            ?
            |onema
        )
        |a
        (?:
            lesper
            |m
        )
        |ea
    )
    |
    (?:
        v
        (?:
            en
        )
        ?
        |imp[or]
        |empo
        |jett
        |un
    )
    i
    |f
    (?:
        o
        (?:
            resea
            |i
        )
        |reema
    )
    |re
    (?:
        (?:
            compa
            |imp
        )
        ri
        |a
    )
    |m
    (?:
        (?:
            idse
        )
        ?a
        |e
    )
    |c
    (?:
        ompari
        |ais
        |rim
    )
    |di
    (?:
        simpri
        |apa
    )
    |g
    (?:
        ran
        |o
    )
    d
    |tr
    (?:
        adesper
        |ea
    )
    |b
    (?:
        rickma
        |i
    )
    |
    (?:
        nonpe
        |a
    )
    r
    |l
    (?:
        iai
        |es
    )
    |outrea
    |whore
)
son' , '.*son' );

cmp_ok( Regexp::Assemble->new->add( qw/
    deathweed deerweed deeded detached debauched deboshed detailed
    defiled deviled defined declined determined declared deminatured
    debentured deceased decomposed demersed depressed dejected
    deflected delighted
/ )->as_string(indent => 2), 'eq',
'de
(?:
  c
  (?:
    (?:
      ompo
      |ea
    )
    s
    |l
    (?:
      ar
      |in
    )
  )
  |b
  (?:
    (?:
      auc
      |os
    )
    h
    |entur
  )
  |t
  (?:
    a
    (?:
      ch
      |il
    )
    |ermin
  )
  |f
  (?:
    i[ln]
    |lect
  )
  |m
  (?:
    inatur
    |ers
  )
  |
  (?:
    ligh
    |jec
  )
  t
  |e
  (?:
    rwe
    |d
  )
  |athwe
  |press
  |vil
)
ed', 'indent de.*ed' );

cmp_ok( Regexp::Assemble->new->add( qw/
    looked choked hooked stoked toked baked faked
    / )->as_string( indent => 0 ), 'eq',
    '(?:(?:[hl]o|s?t|ch)o|[bf]a)ked',
    'looked choked hooked stoked toked baked faked' );

cmp_ok( Regexp::Assemble->new->lookahead(1)->add( qw/
    bird cat dog
    / )->as_string, 'eq',
    '(?=[bcd])(?:bird|cat|dog)', 'lookahead bcd' );

cmp_ok( Regexp::Assemble->new->lookahead(1)->add( qw/
    seahorse season
    / )->as_string, 'eq',
    'sea(?=[hs])(?:horse|son)', 'lookahead seahorse season' );

cmp_ok( Regexp::Assemble->new(lookahead => 1)->add( qw/
    car carrot
    / )->as_string, 'eq',
    'car(?:rot)?', 'lookahead car carrot' );

cmp_ok( Regexp::Assemble->new->lookahead->add( qw/
    car carrot card
    / )->as_string, 'eq',
    'car(?:(?=[dr])(?:rot|d))?', 'lookahead car carrot card' );

cmp_ok( Regexp::Assemble->new->lookahead->add( qw/
    car cart card carp
    / )->as_string, 'eq',
    'car[dpt]?', 'lookahead car carp cart card' );

cmp_ok( Regexp::Assemble->new->lookahead->add( qw/
    car cart card carp carion
    / )->as_string, 'eq',
    'car(?:(?=[dipt])(?:[dpt]|ion))?', 'lookahead car carp cart card carion' );

cmp_ok( Regexp::Assemble->new->lookahead->add( qw/
    car cart card carp carion caring
    / )->as_string, 'eq',
    'car(?:(?=[dipt])(?:[dpt]|i(?=[no])(?:ng|on)))?',
    'lookahead car carp cart card carion caring' );

cmp_ok( Regexp::Assemble->new(lookahead => 1)->add( qw/
    bane bare cane care
    / )->debug(0)->as_string, 'eq',
    '[bc]a[nr]e', 'lookahead cane care bane bare' );

cmp_ok( Regexp::Assemble->new(lookahead => 1)->add( qw/
    faction reaction transaction
    / )->as_string, 'eq',
    '(?=[frt])(?:trans|re|f)action', 'lookahead faction reaction transaction' );

cmp_ok( Regexp::Assemble->new(lookahead => 1)->add( qw/
    faction reaction transaction direction section
    / )->as_string, 'eq',
    '(?=[dfrst])(?:(?=[frt])(?:trans|re|f)a|(?=[ds])(?:dir|s)e)ction',
    'lookahead faction reaction transaction direction section' );

cmp_ok( Regexp::Assemble->new(lookahead => 1)->add( qw/
    card caret corn corpse
    / )->as_string, 'eq',
    'c(?=[ao])(?:or(?=[np])(?:pse|n)|ar(?=[de])(?:et|d))',
    'lookahead card caret corn corpse' );

cmp_ok( Regexp::Assemble->new(lookahead => 1)->add( qw/
    refuse use
    / )->as_string, 'eq',
    '(?=[ru])(?:ref)?use',
    'lookahead use refuse' );

cmp_ok( Regexp::Assemble->new(lookahead => 1)->add( qw/
    caret caress careful careless caring carion carry carried
    / )->as_string, 'eq',
    'car(?=[eir])(?:e(?=[flst])(?:(?=[ls])(?:le)?ss|ful|t)|i(?=[no])(?:ng|on)|r(?=[iy])(?:ied|y))',
    'lookahead caret caress careless careful caring carion carry carried' );

cmp_ok( Regexp::Assemble->new(lookahead => 1)->add( qw/
        unimprison unison unpoison unprison unreason unseason
        unson urson venison ventrimeson vison
    / )->as_string, 'eq',
    '(?=[uv])(?:u(?=[nr])(?:n(?=[iprs])(?:(?=[ip])(?:(?:p[or]|impr))?i|(?:sea)?|rea)|r)|v(?=[ei])(?:en(?=[it])(?:trime|i)|i))son',
    'lookahead u.*son v.*son' );

cmp_ok( $_, 'eq', $fixed, '$_ has not been altered' );

