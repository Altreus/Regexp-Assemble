# 03_str.t
#
# Test suite for Regexp::Assemble
# Make sure the basic stuff works
#
# copyright (C) 2004 David Landgren

use strict;
use Test::Simple tests => 22;

use Regexp::Assemble;

ok( Regexp::Assemble->new->as_string eq '', 'empty' );

my $ra;

ok( Regexp::Assemble->new
	->insert( '' )
	->as_string eq '(?:)?', '//' );

ok( Regexp::Assemble->new
	->insert( 'd' )
	->as_string eq 'd', '/d/' );

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
