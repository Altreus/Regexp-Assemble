# 03_str.t
#
# Test suite for Regexp::Assemble
# Make sure the basic stuff works
#
# copyright (C) 2004 David Landgren

use strict;
use Test::Simple tests => 70;

use Regexp::Assemble;

ok( Regexp::Assemble->new->as_string eq '^a\bz', 'empty' );

ok( Regexp::Assemble->new
    ->insert( '' )
    ->as_string eq '(?:)?', '//' );

ok( $_ = Regexp::Assemble->new
    ->insert( 'd' )
    ->as_string eq 'd', '/d/' ) or print "# r=<$_>\n";

ok( Regexp::Assemble->new
    ->insert( 'd' )
    ->insert( 'o' )
    ->insert( 't' )
    ->as_string eq '[dot]', '/d/ /o/ /t/' );

ok( Regexp::Assemble->new
    ->insert( 'd' )
    ->insert( '' )
    ->as_string eq 'd?', '// /d/' );

ok( Regexp::Assemble->new
    ->insert( 'd', 'a' )
    ->as_string eq 'da', '/da/' );

ok( Regexp::Assemble->new
    ->insert( 'd' )
    ->insert( 'd', 'a' )
    ->as_string eq 'da?', '/d/ /da/' );

ok( Regexp::Assemble->new
    ->insert( '' )
    ->insert( 'd', 'a' )
    ->as_string eq '(?:da)?', '// /da/' );

ok( Regexp::Assemble->new
    ->insert( '' )
    ->insert( 'a' )
    ->insert( 'd' )
    ->as_string eq '[ad]?', '// /a/ /d/' );

ok( Regexp::Assemble->new
    ->insert( '' )
    ->insert( 'a' )
    ->insert( 'd', 'o' )
    ->as_string eq '(?:do|a)?', '// /a/ /do/' );

ok( Regexp::Assemble->new
    ->insert( 'x' )
    ->insert( '.' )
    ->as_string eq '.', '/x/ /./' );

ok( Regexp::Assemble->new
    ->insert( '\033' )
    ->insert( '.' )
    ->as_string eq '.', '/\x033/ /./' );

ok( Regexp::Assemble->new
    ->insert( '\\d' )
    ->insert( '\\s' )
    ->insert( '.' )
    ->as_string eq '.', '/\d/ /\s/ /./' );

ok( Regexp::Assemble->new
    ->insert( '\\d' )
    ->insert( '\\D' )
    ->as_string eq '.', '/\d/ /\D/' );

ok( Regexp::Assemble->new
    ->insert( '\\s' )
    ->insert( '\\S' )
    ->as_string eq '.', '/\s/ /\S/' );

ok( Regexp::Assemble->new
    ->insert( '\\w' )
    ->insert( '\\W' )
    ->as_string eq '.', '/\w/ /\W/' );

ok( Regexp::Assemble->new
    ->insert( '\\w' )
    ->insert( '\\W' )
    ->insert( '	' ) # that's a TAB character, by the way
    ->as_string eq '.', '/\w/ /\W/ /\t/' );

ok( ($_ = Regexp::Assemble->new
    ->insert( '\\d' )
    ->insert( '5' )
    ->as_string) eq '\\d', '/\d/ /5/' ) or warn "# $_\n";

ok( ($_ = Regexp::Assemble->new
    ->insert( '\\d' )
    ->insert( '5' )
    ->insert( '' )
    ->as_string) eq '\\d?', '/\d/ /5/ //' ) or warn "# $_\n";

ok( ($_ = Regexp::Assemble->new
    ->insert( '\\s' )
    ->insert( ' ' )
    ->as_string) eq '\\s', '/\s/ / /' ) or warn "# $_\n";

ok( ($_ = Regexp::Assemble->new
    ->insert( '\\s' )
    ->insert( '' )
    ->as_string) eq '\\s?', '/\s/ //' ) or warn "# $_\n";

ok( ($_ = Regexp::Assemble->new
    ->insert( '\\d' )
    ->insert( '5' )
    ->insert( '7' )
    ->insert( '0' )
    ->as_string) eq '\\d', '/\d/ /0/ /5/ /7/' ) or warn "# $_\n";

ok( ($_ = Regexp::Assemble->new
    ->insert( '\\d' )
    ->insert( 'x' )
    ->insert( '5' )
    ->insert( '7' )
    ->insert( '0' )
    ->as_string) eq '[\\dx]', '/\d/ /x/ /0/ /5/ /7/' ) or warn "# $_\n";

ok( ($_ = Regexp::Assemble->new
    ->insert( '\\d' )
    ->insert( '\\s' )
    ->insert( ' ' )
    ->insert( '5' )
    ->insert( '7' )
    ->insert( '0' )
    ->as_string) eq '[\\d\\s]', '/\d/ /\s/ / / /0/ /5/ /7/' ) or warn "# $_\n";

ok( ($_ = Regexp::Assemble->new
    ->insert( '\\.' )
    ->insert( 'p' )
    ->as_string) eq '[.p]', '/\./ /p/' ) or warn "# $_\n";

ok( ($_ = Regexp::Assemble->new
    ->insert( '\\w' )
    ->insert( '5' )
    ->insert( '1' )
    ->insert( '0' )
    ->insert( 'a' )
    ->insert( '_' )
    ->as_string) eq '\\w', '/\w/ /_/ /a/ /0/ /5/ /1/' ) or warn "# $_\n";

ok( ($_ = Regexp::Assemble->new
    ->insert( '\\d' )
    ->insert( '\\^' )
    ->insert( '' )
    ->as_string) eq '[\\d^]?', '/\d/ /^/ //' ) or warn "# $_\n";

ok( Regexp::Assemble->new
    ->insert( 'a', "\@", 'z' )
    ->insert( 'a', "\?", 'z' )
    ->as_string eq 'a[?@]z', '/a\@z/ /a\?z/' );

ok( ($_ = Regexp::Assemble->new
    ->insert( '\\+' )
    ->as_string) eq '\\+', '/\+/' ) or warn "# $_\n";

ok( ($_ = Regexp::Assemble->new
    ->insert( '\\+' )
    ->insert( '\\*' )
    ->as_string) eq '[*+]', '/\+/ /\*/' ) or warn "# $_\n";

ok( ($_ = Regexp::Assemble->new
    ->insert( '-' )
    ->insert( 'z' )
    ->insert( '0' )
    ->as_string) eq '[-0z]', '/-/ /0/ /z/' ) or warn "# $_\n";

ok( ($_ = Regexp::Assemble->new
    ->insert( '-' )
    ->insert( '\\+' )
    ->insert( '\\*' )
    ->as_string) eq '[-*+]', '/-/ /\+/ /\*/' ) or warn "# $_\n";

ok( ($_ = Regexp::Assemble->new
    ->insert( '^' )
    ->insert( 'z' )
    ->insert( '0' )
    ->as_string) eq '[0z^]', '/^/ /0/ /z/' ) or warn "# $_\n";

ok( ($_ = Regexp::Assemble->new
    ->insert( '^' )
    ->insert( 'z' )
    ->insert( '-' )
    ->insert( '0' )
    ->as_string) eq '[-0z^]', '/^/ /-/ /0/ /z/' ) or warn "# $_\n";

ok( ($_ = Regexp::Assemble->new
    ->insert( '^' )
    ->insert( '\w' )
    ->insert( 'z' )
    ->insert( '-' )
    ->insert( '0' )
    ->as_string) eq '[-\w^]', '/^/ /-/ /0/ /\w/ /z/' ) or warn "# $_\n";

ok( ($_ = Regexp::Assemble->new
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
    ->as_string) eq '\\d', '/0/ .. /9/' ) or warn "# $_\n";

ok( Regexp::Assemble->new
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
    ->as_string eq '[\\dx]', '/0/ .. /9/ /x/' );

ok( Regexp::Assemble->new
    ->insert( '' )
    ->insert( 'b', 'e' )
    ->insert( 'b', 'y' )
    ->as_string eq '(?:b[ey])?', '// /be/ /by/' );

ok( Regexp::Assemble->new
    ->insert( '' )
    ->insert( 'b', 'e' )
    ->insert( 'd', 'o' )
    ->as_string eq '(?:be|do)?', '// /be/ /do/' );

ok( Regexp::Assemble->new
    ->insert( '' )
    ->insert( 'a' )
    ->insert( 'b', 'e' )
    ->insert( 'b', 'y' )
    ->as_string eq '(?:b[ey]|a)?', '// /a/ /be/ /by/' );

ok( Regexp::Assemble->new
    ->insert( 'd', 'a', 'b' )
    ->insert( 'd', 'a', 'y' )
    ->as_string eq 'da[by]', '/dab/ /day/' );

ok( Regexp::Assemble->new
    ->insert( 'd', 'a', 'b' )
    ->insert( 'd', 'a', 'i', 'l', 'y' )
    ->as_string eq 'da(?:ily|b)', '/dab/ /daily/' );

ok( Regexp::Assemble->new
    ->insert( 'd', 'a', 'b' )
    ->insert( 'd', 'a', 'y' )
    ->insert( 'd', 'a', 'i', 'l', 'y' )
    ->as_string eq 'da(?:(?:il)?y|b)', '/dab/ /day/ /daily/' );

ok( Regexp::Assemble->new
    ->insert( 'd', 'a', 'b' )
    ->insert( 'd', 'a', 'b', 'b', 'l', 'e' )
    ->as_string eq 'dab(?:ble)?', '/dab/ /dabble/' );

ok( Regexp::Assemble->new
    ->insert( 'd', 'o', 'b' )
    ->insert( 'd', 'o', 'e' )
    ->insert( 'd', 'o', 'g' )
    ->insert( 'd', 'o', 'n' )
    ->insert( 'd', 'o', 't' )
    ->insert( 'd', 'u', 'b' )
    ->insert( 'd', 'u', 'd' )
    ->as_string eq 'd(?:o[begnt]|u[bd])', '/dob/ /doe/ /dog/ /don/ /dot/ /dub/ /dud/' );

ok( Regexp::Assemble->new
    ->insert( 'd' )
    ->insert( 'd', 'o' )
    ->insert( 'd', 'o', 'n' )
    ->insert( 'd', 'o', 'n', 'e' )
    ->as_string eq 'd(?:o(?:ne?)?)?', '/d/ /do/ /don/ /done/' );

ok( Regexp::Assemble->new
    ->insert( '' )
    ->insert( 'd' )
    ->insert( 'd', 'o' )
    ->insert( 'd', 'o', 'n' )
    ->insert( 'd', 'o', 'n', 'e' )
    ->as_string eq '(?:d(?:o(?:ne?)?)?)?', '// /d/ /do/ /don/ /done/' );

ok( Regexp::Assemble->new
    ->insert( 'd', 'a', 'y' )
    ->insert( 'n', 'i', 'g', 'h', 't' )
    ->as_string eq '(?:night|day)', '/day/ /night/' );

ok( Regexp::Assemble->new
    ->insert( 'd', 'a', 'm', 'p' )
    ->insert( 'd', 'a', 'm', 'e' )
    ->insert( 'd', 'a', 'r', 't' )
    ->insert( 'd', 'a', 'r', 'k' )
    ->as_string eq 'da(?:m[ep]|r[kt])', '/dame/ /damp/ /dark/ /dart/' );

ok( ($_ = Regexp::Assemble->new
    ->add( qw/foo bar/ )
    ->as_string(indent => 2))
eq
'(?:
  bar
  |foo
)'
, 'pretty foo bar' ) or print "\n# <$_>\n";

ok( ($_ = Regexp::Assemble->new
    ->add( qw/food fool bar/ )
    ->as_string(indent => 2))
eq
'(?:
  foo[dl]
  |bar
)'
, 'pretty food fool bar' ) or print "\n# <$_>\n";

ok( ($_ = Regexp::Assemble->new
    ->add( qw/afood afool abar/ )
    ->as_string(indent => 2))
eq
'a
(?:
  foo[dl]
  |bar
)'
, 'pretty afood afool abar' ) or print "\n# <$_>\n";

ok( ($_ = Regexp::Assemble->new
    ->add( qw/dab dam day/ )
    ->as_string(indent => 2))
eq 'da[bmy]'
, 'pretty dab dam day' ) or print "\n# <$_>\n";

ok( ($_ = Regexp::Assemble->new
    ->add( qw/be bed/ )
    ->as_string(indent => 2))
eq 'bed?'
, 'pretty be bed' ) or print "\n# <$_>\n";

ok( ($_ = Regexp::Assemble->new
    ->add( qw/be bed beg bet / )
    ->as_string(indent => 2))
eq 'be[dgt]?'
, 'pretty be bed beg bet' ) or print "\n# <$_>\n";

ok( ($_ = Regexp::Assemble->new
    ->add( qw/afoodle afoole abarle/ )
    ->as_string(indent => 2))
eq
'a
(?:
  food?
  |bar
)
le'
, 'pretty afoodle afoole abarle' ) or print "\n# <$_>\n";

ok( ($_ = Regexp::Assemble->new
    ->add( qw/afar afoul abate aback/ )
    ->as_string(indent => 2))
eq
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
, 'pretty pretty afar afoul abate aback' ) or print "\n# <$_>\n";


ok( ($_ = Regexp::Assemble->new
    ->add( qw/stormboy steamboy saltboy sockboy/ )
    ->as_string(indent => 5))
eq
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
, 'pretty stormboy steamboy saltboy sockboy' ) or print "\n# <$_>\n";

ok( ($_ = Regexp::Assemble->new
    ->add( qw/stormboy steamboy stormyboy steamyboy saltboy sockboy/ )
    ->as_string(indent => 4))
eq
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
, 'pretty stormboy steamboy stormyboy steamyboy saltboy sockboy' ) or print "\n# <$_>\n";

ok( ($_ = Regexp::Assemble->new
    ->add( qw/stormboy steamboy stormyboy steamyboy stormierboy steamierboy saltboy/ )
    ->as_string(indent => 1))
eq
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
, 'pretty stormboy steamboy stormyboy steamyboy stormierboy steamierboy saltboy' )
    or print "\n# <$_>\n";

ok( ($_ = Regexp::Assemble->new
    ->add( qw/showerless showeriness showless showiness show shows/ )
    ->as_string(indent => 4))
eq
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
?'
, 'pretty showerless showeriness showless showiness show shows' )
    or print "\n# <$_>\n";

ok( ($_ = Regexp::Assemble->new->add( qw/
    showerless showeriness showdeless showdeiness showless showiness show shows
    / )->as_string(indent => 4))
eq
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
?'
, 'pretty showerless showeriness showdeless showdeiness showless showiness show shows' )
    or print "\n# <$_>\n";

ok( ($_ = Regexp::Assemble->new->add( qw/
        yammail\.com yanmail\.com yeah\.net yourhghorder\.com yourload\.com
    / )->as_string(indent => 4))
eq
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
, 'pretty yammail.com yanmail.com yeah.net yourhghorder.com yourload.com' )
    or print "\n# <$_>\n";

ok( ($_ = Regexp::Assemble->new->add( qw/
        200.1 202.1 207.4 208.3 213.2
    / )->as_string(indent => 4))
eq
'2
(?:
    0
    (?:
        [02].1
        |7.4
        |8.3
    )
    |13.2
)'
, 'pretty 200.1 202.1 207.4 208.3 213.2' )
    or print "\n# <$_>\n";

ok( ($_ = Regexp::Assemble->new->add( qw/
        0\.0 0\.2 0\.7 0\.01 0\.003
    / )->as_string(indent => 4))
eq
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
, 'pretty 0.0 0.2 0.7 0.01 0.003' )
    or print "\n# <$_>\n";

ok( ($_ = Regexp::Assemble->new->add( qw/
        convenient consort concert
    / )->as_string(indent => 4))
eq
'con
(?:
    (?:
        ce
        |so
    )
    r
    |venien
)
t'
, 'pretty convenient consort concert' )
    or print "\n# <$_>\n";

ok( ($_ = Regexp::Assemble->new->add( qw/
        convenient containment consort concert
    / )->as_string(indent => 4))
eq
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
, 'pretty convenient containment consort concert' )
    or print "\n# <$_>\n";

ok( ($_ = Regexp::Assemble->new->add( qw/
        sat sit bat bit sad sid bad bid
    / )->as_string(indent => 5))
eq
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
, 'pretty sat sit bat bit sad sid bad bid' )
    or print "\n# <$_>\n";

ok( ($_ = Regexp::Assemble->new->add( qw/
        commercial\.net compuserve\.com compuserve\.net concentric\.net
        coolmail\.com coventry\.com cox\.net
    / )->as_string(indent => 5))
eq
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
, 'pretty c*.*' ) or print "\n# <$_>\n";

ok( ($_ = Regexp::Assemble->new->add( qw/
        ambient\.at agilent\.com americanexpress\.com amnestymail\.com
        amuromail\.com angelfire\.com anya\.com anyi\.com aol\.com
        aolmail\.com artfiles\.de arcada\.fi att\.net
    / )->as_string(indent => 5))
eq
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
)'
, 'pretty a*.*' ) or print "\n# <$_>\n";

