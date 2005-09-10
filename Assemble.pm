# Regexp::Assemple.pm
#
# Copyright (c) 2004-2005 David Landgren
# All rights reserved

package Regexp::Assemble;

use vars qw/$VERSION $have_Storable $Default_Lexer $Single_Char /;
$VERSION = '0.17';

=head1 NAME

Regexp::Assemble - Assemble multiple Regular Expressions into a single RE

=head1 VERSION

This document describes version 0.17 of Regexp::Assemble,
released 2005-09-10.

=head1 SYNOPSIS

  use Regexp::Assemble;
  
  my $ra = Regexp::Assemble->new;
  $ra->add( 'ab+c' );
  $ra->add( 'ab+-' );
  $ra->add( 'a\w\d+' );
  $ra->add( 'a\d+' );
  print $ra->re; # prints a(?:\w?\d+|b+[-c])

=head1 DESCRIPTION

Regexp::Assemble takes an arbitrary number of regular expressions
and assembles them into a single regular expression (or RE) that
will match all that each of the individual REs match.

As a result, instead of having a large list of expressions to loop
over, the string only needs to be tested against one expression.
This is interesting when you have several thousand patterns to deal
with. Serious effort is made to produce the smallest pattern possible.

It is also possible to track the orginal patterns, so that you can
determine which, among the source patterns that form the assembled
pattern, was the one that caused the match to occur.

You should realise that large numbers of alternations are processed
in perl's regular expression engine in O(n) time, not O(1). If you
are still having performance problems, you should look at using a
trie. Note that Perl's own regular expression engine will implement
trie optimisations in perl 5.10 (they are already available in
perl 5.9.3 if you want to try them out). C<Regexp::Assemble> will
do the right thing when it knows it's running on a a trie'd perl.
(At least in some version after this one).

Some more examples of usage appear in the accompanying README. If
that file isn't easy to access locally, you can find it on a web
repository such as L<http://search.cpan.org/> or
L<http://kobesearch.cpan.org/>.

=cut

use strict;
use Carp 'croak';

use constant DEBUG_ADD  => 1;
use constant DEBUG_TAIL => 2;
use constant DEBUG_LEX  => 4;

# The following patterns were generated with eg/naive
$Default_Lexer = qr/(?![[(\\]).(?:[*+?]\??|\{\d+(?:,\d*)?\}\??)?|\\(?:[bABCEGLQUXZ]|[lu].|(?:[^\w]|[aefnrtdDwWsS]|c.|0\d{2}|x(?:[\da-fA-F]{2}|{[\da-fA-F]{4}})|N\{\w+\}|[Pp](?:\{\w+\}|.))(?:[*+?]\??|\{\d+(?:,\d*)?\}\??)?)|\[.*?(?<!\\)\](?:[*+?]\??|\{\d+(?:,\d*)?\}\??)?|\(.*?(?<!\\)\)(?:[*+?]\??|\{\d+(?:,\d*)?\}\??)?/;

$Single_Char   = qr/^(?:\\(?:[aefnrtdDwWsS]|c.|[^\w\/{|}-]|0\d{2}|x(?:[\da-fA-F]{2}|{[\da-fA-F]{4}}))|.)$/;

=head1 METHODS

=over 8

=item new

Creates a new C<Regexp::Assemble> object. A set of key/value parameters
can be supplied to control the finer details of the object's
behaviour.

B<flags>, sets the flags C<imsx> that should be applied to the
resulting pattern. Warning: no error checking is done, you should
ensure that the flags you pass are understood by the version of
Perl in use.

B<chomp>, controls whether the pattern should be chomped before being
lexed. Handy if you are reading lines from a file. By default, no
chomping is performed. See the C<$/> variable in L<perlvar>.

B<lookahead>, controls whether the pattern should contain zero-width
lookahead assertions (C<i.e.> (?=[abc])(?:bob|alice|charles). This is
not activated by default, because in many circumstances the cost of
processing the assertion itself outweighs the benefit of its faculty
for short-circuiting a match that will fail. This is sensitive to
the probability of a match succeding, so if you're worried about
performance you'll have to benchmark a sample population of targets
to see which way the benefits lie.

B<track>, controls whether you want know which of the initial patterns
was the one that matched. See the C<matched> method for more details.
Note that in this mode of operation THERE ARE SECURITY IMPLICATIONS OF
WHICH YOU YOU SHOULD BE AWARE.

B<indent>, the number of spaces used to indent nested grouping of
a pattern. Use this to produce a pretty-printed pattern. See the
C<as_string> method for a more detailed explanation.

B<pre_filter>, allows you to add a callback to enable sanity checks
on the pattern being loaded. This callback is triggered before the
pattern is split apart by the lexer. In other words, it operates
on the entire pattern. If you are loading patterns from a file,
this would be an appropriate place to remove comments.

B<filter>, allows you to add a callback to enable sanity checks on
the pattern being loaded. This callback is triggered after the
pattern has been split apart by the lexer.

B<mutable>, controls whether new patterns can be added to the object
after the RE is generated.

B<reduce>, controls whether tail reduction occurs or not. If set,
patterns like C<a(?:bc+d|ec+d)> will be reduced to C<a[be]c+d>.
That is, the end of the pattern in each part of the b... and d...
alternations is identical, and hence is hoisted out of the alternation
and placed after it. 

B<lex>, specifies the pattern used to lex the input lines into
tokens. You could replace the default pattern by a more sophisticated
version that matches arbitrarily nested parentheses, for example.

B<debug>, controls whether copious amounts of output is produced
during the loading stage or the reducing stage of assembly.

  my $ra = Regexp::Assemble->new;
  my $rb = Regexp::Assemble->new( chomp => 1, debug => 3 );

A more detailed explanation of these attributes follows.

=cut

sub new {
    my $class = shift;
    my %args = @_;
    bless {
        re         => undef,
        str        => undef,
        lex        => exists $args{lex}       ? qr/$args{lex}/   : qr/$Default_Lexer/,
        flags      => exists $args{flags}     ? $args{flags}     : '',
        chomp      => exists $args{chomp}     ? $args{chomp}     : 0,
        indent     => exists $args{indent}    ? $args{indent}    : 0,
        lookahead  => exists $args{lookahead} ? $args{lookahead} : 0,
        track      => exists $args{track}     ? $args{track}     : 0,
        reduce     => exists $args{reduce}    ? $args{reduce}    : 1,
        mutable    => exists $args{mutable}   ? $args{mutable}   : 0,
        debug      => exists $args{debug}     ? $args{debug}     : 0,
        filter     => $args{filter}, # don't care if it's not there
        pre_filter => $args{pre_filter}, # don't care if it's not there
        path    => [],
    },
    $class;
}

=item clone

Clones the contents of a Regexp::Assemble object and creates a new
object (in other words it performs a deep copy).

  my $copy = $ra->clone();

If the Storable module is installed, its dclone method will be used,
otherwise the cloning will be performed using a pure perl approach.

=cut

sub clone {
    my $self = shift;
    my $clone = {
        re         => $self->{re},
        str        => $self->{str},
        lex        => $self->{lex},
        chomp      => $self->{chomp},
        indent     => $self->{indent},
        flags      => $self->{flags},
        lookahead  => $self->{lookahead},
        track      => $self->{track},
        reduce     => $self->{reduce},
        mutable    => $self->{mutable},
        debug      => $self->{debug},
        filter     => $self->{filter},
        pre_filter => $self->{pre_filter},
        path       => _path_clone($self->_path),
    };
    bless $clone, ref($self);
}

=item add(LIST)

Takes a string, breaks it apart into a set of tokens (respecting
meta characters) and inserts the resulting list into the C<R::A>
object. It uses a naive regular expression to lex the string
that may be fooled complex expressions (specifically, it will
fail to lex nested parenthetical expressions such as
C<ab(cd(ef)?gh)ij> correctly). If this is the case, the end of
the string will not be tokenised correctly and returned as one
long string.

On the one hand, this may indicate that the patterns you are
trying to feed the C<R::A> object are too complex. Simpler
patterns might allow the algorithm to work more effectively and
spot reductions in the resulting pattern.

On the other hand, you can supply your own pattern to perform the
lexing if you need. The test suite contains an example of a lexer
pattern that will match one level of nested parentheses.

Note that there is an internal optimisation that will bypass a
much of the lexing process. If a string contains no C<\>
(backslash), C<[> (open square bracket), C<(> (open paren),
C<?> (question mark), C<+> (plus), C<*> (star) or C<{> (open
curly), a character split will be performed directly.

A list of strings may be supplied, thus you can pass it a file
handle of a file opened for reading:

    $re->add( '\d+-\d+-\d+-\d+\.example\.com' );
    $re->add( <IN> );

You probably need to set the C<chomp> attribute on the object to
get files to work correctly:

    my $re = Regexp::Assemble->new( chomp=>1 )->add( <IN> );
    # or
    my $re = Regexp::Assemble->new;
    $re->chomp(1)->add( <IN> );

If the file is very large, it may be more efficient to use a
C<while> loop, to read the file line-by-line:

    $re->->add($_) while <IN>;

The pre_filter method provides allows you to filter input on a
line-by-line basis.

This method is chainable.

=cut

sub _lex {
    my $self   = shift;
    my $debug  = $self->{debug} & DEBUG_LEX;
    my $record = shift;
    $debug and print "lex in $record\n";
    return [ split //, $record ] unless $record =~ /[\\[(?+*{\/]/;
    return $self->_lex_stateful( $record ) if $record =~ /\\[LQUlu]/;
    my $len    = 0;
    my @path   = ();
    my ($diff, $token_len);
    while( $record =~ /($self->{lex})/g ) {
        my $token = $1;
        $token_len = length($token);
        $debug and print "lexed <$token> len=$token_len\n";
        if( pos($record) - $len > $token_len ) {
            push @path,  substr( $record, $len, $diff = pos($record) - $len - $token_len );
            $debug and print(" recover ", substr( $record, $len, $diff = pos($record) - $len - $token_len ), "\n");
            $len += $diff;
        }
        if( substr( $token, 0, 1 ) eq '\\' ) {
            $debug and print "leading backslash\n";
            $token = quotemeta(chr(hex($1))) if $token =~ /^\\x([\da-fA-F]{2})$/;
            # undo quotemeta's brute-force escapades
            $token =~ s/^\\([^\w$()*+.?@\[\\\]^|{\/])$/$1/;
            # $token =~ s/^\\($Un_Quotemeta)$/$1/;
            $debug and print "  add backslash <$token>\n";
            push @path, $token unless $token eq '\\E';
        }
        else {
            $token = '\\/' if $token eq '/';
            $debug and print "  add <$token>\n";
            push @path, $token;
        }
        $len += $token_len;
    }
    push @path, substr($record,$len) if $len < length($record);
    \@path;
}

sub _lex_stateful {
    my $self   = shift;
    my $debug  = $self->{debug} & DEBUG_LEX;
    my $record = shift;
    $debug and print "stateful\n";
    my $len    = 0;
    my @path   = ();
    my ($diff, $token_len);
    my $case = '';
    my $qm = '';
    while( $record =~ /($self->{lex})/g ) {
        my $token = $1;
        $token_len = length($token);
        $debug and print "lexed <$token> len=$token_len\n";
        if( pos($record) - $len > $token_len ) {
            push @path,  substr( $record, $len, $diff = pos($record) - $len - $token_len );
            $debug and print " recover ", substr( $record, $len, $diff ), "\n";
            $len += $diff;
        }
        $len += $token_len;
        if( substr( $token, 0, 1 ) eq '\\' ) {
            $debug and print " leading backslash\n";
            if( $token =~ /^\\([ELQU])$/ ) {
                if( $1 eq 'E' ) {
                    $case = $qm = '';
                }
                elsif( $1 eq 'Q' ) {
                    $qm = $1;
                }
                else {
                    $case = $1;
                }
                next;
            }
            elsif( $token =~ /^\\([lu])(.)$/ ) {
                push @path, $1 eq 'l' ? lc($2) : uc($2);
                next;
            }
            elsif( $token =~ /^\\x([\da-fA-F]{2})$/ ) {
                $token = quotemeta(chr(hex($1)));
            }
            elsif( $qm ) {
                for my $t ( $token =~ /\\?./g ) {
                    $t = quotemeta($t) unless $t =~ /^\\/;
                    $t =~ s/^\\([^\w$()*+.?@\[\\\]^|{\/])$/$1/;
                    push @path, $t;
                }
                next;
            }
        }
        else {
            $case and $token = $case eq 'U' ? uc($token) : lc($token);
            if( $qm ) {
                $token = quotemeta($token);
                for my $t ( $token =~ /\\?./g ) {
                    $t = quotemeta($t) unless $t =~ /^\\/;
                    $t =~ s/^\\([^\w$()*+.?@\[\\\]^|{\/])$/$1/;
                    push @path, $t;
                }
                next;
            }
            $token = '\\/' if $token eq '/';
        }
        # undo quotemeta's brute-force escapades
        $token =~ s/^\\([^\w$()*+.?@\[\\\]^|{\/])$/$1/;
        $debug and print "  <$token> case=<$case> qm=<$qm>\n";
        push @path, $token;
    }
    push @path, substr($record,$len) if $len < length($record);
    $debug and print "-> stateful out <@path>\n";
    \@path;
}

sub add {
    my $self = shift;
    my $record;
    my $debug  = $self->{debug} & DEBUG_LEX;
    while( defined( $record = shift @_ )) {
        chomp($record) if $self->{chomp};
        next if $self->{pre_filter} and not $self->{pre_filter}->($record);
        $debug and print "add <$record>\n";
        my $list = $self->_lex($record);
        next if $self->{filter} and not $self->{filter}->(@$list);
        $self->_insertr( $list );
    }
    $self;
}

=item insert(LIST)

Takes a list of tokens representing a regular expression and
stores them in the object. Note: you should not pass it a bare
regular expression, such as C<ab+c?d*e>. You must pass it as
a list of tokens, I<e.g.> C<('a', 'b+', 'c?', 'd*', 'e')>.

This method is chainable, I<e.g.>:

  my $ra = Regexp::Assemble->new
    ->insert( qw[ a b+ c? d* e ] )
    ->insert( qw[ a c+ d+ e* f ] );

The C<add> method calls C<insert> internally.

The C<filter> method allows you to accept or reject the
addition of the entire pattern on a token-by-token basis.

=cut

sub insert {
    my $self = shift;
    return if $self->{filter} and not $self->{filter}->(@_);
    $self->_insertr( [@_] );
    $self;
}

sub _insertr {
    my $self = shift;
    my $debug = $self->{debug} & DEBUG_LEX;
    $self->{path} = _insert_path( $self->_path, $self->_debug(DEBUG_ADD), $_[0] );
    $self->{str} = $self->{re} = undef;
}

=item as_string

Assemble the expression and return it as a string. You may want to do
this if you are writing the pattern to a file. The following arguments
can be passed to control the aspect of the resulting pattern:

B<indent>, the number of spaces used to indent nested grouping of
a pattern. Use this to produce a pretty-printed pattern (for some
definition of "pretty"). The resulting output is rather verbose. The
reason is to ensure that the metacharacters C<(?:> and C<)> always
occur on otherwise empty lines. This allows you grep the result for an
even more synthetic view of the pattern:

  egrep -v '^ *[()]' <regexp.file>

The result of the above is quite readable. Remember to backslash the
spaces appearing in your own patterns if you wish to use an indented
pattern in an C<m/.../x> construct. Indenting is ignored if tracking
is enabled.

The B<indent> argument takes precedence over the C<indent>
method/attribute of the object.

If you have not set the B<mutable> attribute on the object, calling this
method will drain the internal data structure. Large numbers of patterns
can eat a significant amount of memory, and this lets perl recover the
memory used. Mutable means that you want to keep the internal data
structure lying around in order to add additional patterns to the object
after an assembled pattern has been produced.

If you want to reduce the pattern I<and> continue to add new patterns,
clone the object and reduce the clone, leaving the original object alone.

=cut

sub as_string {
    my $self = shift;
    if( not defined $self->{str} ) {
        if( $self->{track} ) {
            $self->{m}      = undef;
            $self->{mcount} = 0;
            $self->{mlist}  = [];
            $self->{str}    = _re_path_track($self, $self->_path, '', '');
        }
        else {
            $self->_reduce unless ($self->{mutable} or not $self->{reduce});
            my $arg  = {@_};
            $arg->{indent} = $self->{indent}
                if not exists $arg->{indent} and $self->{indent} > 0;
            if( exists $arg->{indent} and $arg->{indent} > 0 ) {
                $arg->{depth} = 0;
                $self->{str}  = _re_path_pretty($self->_path, $arg);
            }
            elsif( $self->{lookahead} ) {
                $self->{str}  = _re_path_lookahead($self->_path);
            }
            else {
                $self->{str}  = _re_path($self->_path);
            }
        }
        $self->{path} = [] unless $self->{mutable};
    }
    # the assembled pattern, otherwise explicitly match nothing
    length($self->{str}) ? $self->{str} : '^a\bz';
}

=item re

Assembles the pattern and return it as a compiled RE, using the
C<qr//> operator.

As with C<as_string>, calling this method will reset the internal data
structures to free the memory used in assembling the RE. This behaviour
can be controlled with the C<mutable> attribute.

The B<indent> attribute, documented in the C<as_string> method, can be
used here (it will be ignored if tracking is enabled).

With method chaining, it is possible to produce a RE without having
a temporary C<Regexp::Assemble> object lying around, I<e.g.>:

  my $re = Regexp::Assemble->new
    ->add( q[ab+cd+e] )
    ->add( q[ac\\d+e] )
    ->add( q[c\\d+e] )
    ->re;

The C<$re> variable now contains a Regexp object that can be used
directly:

  while( <> ) {
    /$re/ and print "Something in [$_] matched\n";
  )

The C<re> method is called when the object is used in string context
(hence, withing an C<m//> operator), so by and large you do not even
need to save the RE in a separate variable. The following will work
as expected:

  my $re = Regexp::Assemble->new->add( qw[ fee fie foe fum ] );
  while( <IN> ) {
    if( /($re)/ ) {
      print "Here be giants: $1\n";
    }
  }

This approach does not work with tracked patterns. The
C<match> and C<matched> methods must be used instead, see below.

=cut

sub re {
    my $self = shift;
    $self->_build_re($self->as_string(@_)) unless defined $self->{re};
    $self->{re};
}

sub _build_re {
    my $self = shift;
    my $str  = shift;
    if( $self->{track} ) {
        use re 'eval';
        $self->{re} = length $self->{flags}
            ? qr/(?$self->{flags}:$str)/
            : qr/$str/;
    }
    else {
        $self->{re} = length $self->{flags}
            ? qr/(?$self->{flags}:$str)/
            : qr/$str/;
    }
}

# strip off the garbage that overloading wishes to provide us.
# see perldoc overload, section " Calling Conventions for Unary
# Operations". Credit to [bart] on the Perlmonks chatterbox for
# showing me this technique.

use overload '""' => sub { $#_ = 0; goto &re };

=item match(SCALAR)

If pattern tracking is in use, you must C<use re 'eval'> in order
to make things work correctly. At a minimum, this will make your
code look like this:

    my $did_match = do { use re 'eval'; $target =~ /$ra/ }
    if( $did_match ) {
        print "matched ", $ra->matched, "\n";
    }

(The main reason is that the C<$^R> variable is currently broken
and an ugly workaround is required. See Perl bug #32840 for more
information if you are curious. The README also contains more
information).

The important thing to note is that with C<use re 'eval'>, THERE
ARE SECURITY IMPLICATIONS WHICH YOU IGNORE AT YOUR PERIL. The problem
is this: if you do not have strict control over the patterns being
fed to C<Regexp::Assemble> when tracking is enabled, and someone
slips you a pattern such as C</^(?{system 'rm -rf /'})/> and you
attempt to match a string against the resulting pattern, you will
know Fear and Loathing.

What is more, the C<$^R> workaround means that that tracking does
not work if you perform a bare C</$re/> pattern match as shown
above. You have to instead call the C<match> method, in order to
supply the necessary context to take care of the tracking housekeeping
details.

   if( defined( my $match = $ra->match($_)) ) {
       print "  $_ matched by $match\n";
   }

In the case of a successul match, the original matched pattern
is returned directly. The matched pattern will also be available
through the C<matched> method.

(Except that the above is not true for 5.6.0: the C<match> method
returns true or undef, and the C<matched> method always returns
undef).

If you are capturing parts of the pattern I<e.g.> C<foo(bar)rat>
you will want to get at the captures. See the C<mbegin>, C<mend>,
C<mvar> and C<capture> methods. If you are not using captures
then you may safely ignore this section.

=cut

sub match {
    my $self = shift;
    my $target = shift;
    if( !$self->{re} ) {
        $self->_build_re($self->as_string(@_)) unless defined $self->{re};
    }
    $self->{m}    = undef;
    $self->{mvar} = [];
    if( not $target =~ /$self->{re}/ ) {
        $self->{mbegin} = [];
        $self->{mend}   = [];
        return undef;
    }
    $self->{mbegin} = _path_copy([@-]);
    $self->{mend}   = _path_copy([@+]);
    my $n = 0;
    for( my $n = 0; $n < @-; ++$n ) {
        push @{$self->{mvar}}, substr($target, $-[$n], $+[$n] - $-[$n])
            if defined $-[$n] and defined $+[$n];
    }
    if( $self->{track} ) {
        defined $self->{m} ? $self->{mlist}[$self->{m}] : 1;
    }
    else {
        1;
    }
}

=item mbegin

This method returns a copy of C<@-> at the moment of the
last match. You should ordinarily not need to bother with
this, C<mvar> should be able to supply all your needs.

=cut

sub mbegin {
    my $self = shift;
    exists $self->{mbegin} ? $self->{mbegin} : [];
}

=item mend

This method returns a copy of C<@+> at the moment of the
last match.

=cut

sub mend {
    my $self = shift;
    exists $self->{mend} ? $self->{mend} : [];
}

=item mvar(NUMBER)

The C<mvar> method returns the captures of the last match.
C<mvar(1)> corresponds to $1, C<mvar(2)> to $2, and so on.
C<mvar(0)> happens to return the target string matched,
as a byproduct of walking down the C<@-> and C<@+> arrays
after the match.

If called without a parameter, C<mvar> will return a
reference to an array containing all captures.

=cut

sub mvar {
    my $self = shift;
    return undef unless exists $self->{mvar};
    defined($_[0]) ? $self->{mvar}[$_[0]] : $self->{mvar};
}

=item capture

The C<capture> method returns the the captures of the last
match as an array. Unlink C<mvar>, this method does not
include the matched string. It is equivalent to getting an
array back that contains C<$1, $2, $3, ...>.

If no captures were found in the match, an empty array is
returned, rather than undef. You are therefore guaranteed
to be able to use C<for my $c (@{$re->capture}) { ...> without
have to check whether C<capture> returns a valid array.

=cut

sub capture {
    my $self = shift;
    if( $self->{mvar} ) {
        my @capture = @{$self->{mvar}};
        shift @capture;
        return @capture;
    }
    return ();
}

=item matched

If pattern tracking has been set, via the C<track> attribute,
or through the C<track> method, this method will return the
original pattern of the last successful match. Returns undef
match has yet been performed, or tracking has not been enabled.

See below in the NOTES section for additional subtleties of
which you should be aware of when tracking patterns.

Note that this method is not available in 5.6.0, due to
limitations in the implementation of C<(?{...})> at the time.

=cut

sub matched {
    my $self = shift;
    defined $self->{m} ? $self->{mlist}[$self->{m}] : undef;
}

=item debug(NUMBER)

Turns debugging on or off. Statements are printed
to the currently selected file handle (STDOUT by default).
If you are already using this handle, you will have to
arrange to select an output handle to a file of your own
choosing, before call the C<add>, C<as_string> or C<re>)
functions, otherwise it will scribble all over your
carefully formatted output.

0 turns debugging off, 1 emits debug traces dealing with
adding new patterns to the object, 2 emits debug traces
dealing with the reduction of the assembled pattern. 4 emits
debug traces dealing with the lexing of the input pattern.
Calling with no arguments also turns debugging off.

Values can be added (or or'ed together) to trace everything

   $r->debug(1)->add( '\\d+abc' );

=cut

sub debug {
    my $self = shift;
    $self->{debug} = defined($_[0]) ? $_[0] : 0;
    $self;
}

=item dump

Produces a synthetic view of the internal data structure. How
to interpret the results is left as an exercise to the reader.

  print $r->dump;

=cut

sub dump {
    _dump($_[0]->_path);
}

=item chomp(0|1)

Turns chomping on or off. When loading an object from a
file the lines will contain their line separator token. This
may produce undesired results. In this case, call chomp with
a value of 1 to enable autochomping. Chomping is off by default.

  $re->chomp( 1 );
  $re->add( <DATA> );

=cut

sub chomp {
    my $self = shift;
    $self->{chomp} = defined($_[0]) ? $_[0] : 1;
    $self;
}

=item indent(NUMBER)

Sets the level of indent for pretty-printing nested groups
within a pattern. See the C<as_string> method for more details.
When called without a parameter, no indenting is performed.

  $re->indent( 4 );
  print $re->as_string;

=cut

sub indent {
    my $self = shift;
    $self->{indent} = defined($_[0]) ? $_[0] : 0;
    $self;
}

=item lookahead(0|1)

Turns on zero-width lookahead assertions. This is usually
beneficial when you expect that the pattern will usually fail.
If you expect that the pattern will usually match you will
probably be worse off.

=cut

sub lookahead {
    my $self = shift;
    $self->{lookahead} = defined($_[0]) ? $_[0] : 1;
    $self;
}

=item flags(STRING)

Sets the flags that govern how the pattern behaves (for
versions of Perl up to 5.9 or so, these are C<imsx>). By
default no flags are enabled.

=cut

sub flags {
    my $self = shift;
    $self->{flags} = defined($_[0]) ? $_[0] : '';
    $self;
}

=item track(0|1)

Turns tracking on or off. When this attribute is enabled,
additional housekeeping information is inserted into the
assembled expression using C<({...}> embedded code
constructs. This provides the necessary information to
determine which, of the original patterns added, was the
one that caused the match.

  $re->track( 1 );
  if( $target =~ /$re/ ) {
    print "$target matched by ", $re->matched, "\n";
  }

Note that when this functionality is enabled, no
reduction is performed and no character classes are
generated. In other words, C<brag|tag> is not
reduced down to C<(?:br|t)ag> and C<dig|dim> is not
reduced to C<di[gm]>.

=cut

sub track {
    my $self = shift;
    $self->{track} = defined($_[0]) ? $_[0] : 1;
    $self;
}

=item pre_filter(CODE)

Allows you to install a callback to check that the pattern being
loaded contains valid input. It receives the pattern as a whole
to be added, before it been tokenised by the lexer. It may to return 0 or undef to
indicate that the pattern should not be added, any true value
indicates that the contents are fine.

TODO: how to remove comments

If you want to remove the filter, pass C<undef> as a parameter.

  $ra->pre_filter(undef);

This method is chainable.

=cut

sub pre_filter {
    my $self   = shift;
    my $pre_filter = shift;
    if( defined $pre_filter and ref($pre_filter) ne 'CODE' ) {
        croak "pre_filter method not passed a coderef\n";
    }
    $self->{pre_filter} = $pre_filter;
    $self;
}


=item filter(CODE)

Allows you to install a callback to check that the pattern being
loaded contains valid input. It receives a list on input, after it
has been tokenised by the lexer. It may to return 0 or undef to
indicate that the pattern should not be added, any true value
indicates that the contents are fine.

If you know that all patterns you expect to assemble contain
a restricted set of of tokens (e.g. no spaces), you could do
the following:

  $ra->filter(sub { not grep { / / } @_ });

or

  sub only_spaces_and_digits {
    not grep { ![\d ] } @_
  }
  $ra->filter( \&only_spaces_and_digits );

These two examples will silently ignore faulty patterns, If you
want the user to be made aware of the problem you should raise an
error (via C<warn> or C<die>), log an error message, whatever is
best. If you want to remove a filter, pass C<undef> as a parameter.

  $ra->filter(undef);

This method is chainable.

=cut

sub filter {
    my $self   = shift;
    my $filter = shift;
    if( defined $filter and ref($filter) ne 'CODE' ) {
        croak "filter method not passed a coderef\n";
    }
    $self->{filter} = $filter;
    $self;
}

=item lex(SCALAR)

Change the pattern used to break a string apart into tokens.
You can examine the C<eg/naive> script as a starting point.

=cut

sub lex {
    my $self = shift;
    $self->{lex} = qr($_[0]);
    $self;
}

=item reduce(0|1)

Turns pattern reduction on or off. A reduced pattern may
be considerably shorter than an unreduced pattern. Consider
C</sl(?:ip|op|ap)/> I<versus> C</sl[aio]p/>. An unreduced
pattern will be very similar to those produced by
C<Regexp::Optimizer>. Reduction is on by default. Turning
it off makes assembly much faster.

=cut

sub reduce {
    my $self = shift;
    $self->{reduce} = defined($_[0]) ? $_[0] : 1;
    $self;
}

=item mutable(0|1)

When the C<re> or C<as_string> methods are called the reduction
algoritm kicks in and takes the current data structure and fold the
common portions of the patterns that have been stored in the object.
Once this occurs, it is no longer possible to add any more
patterns.

In fact, the internal structures are release to free up memory. If
you have a programa that adds additional patterns to an object over
a long period, you can set the mutable attribute. This will stop the
internal structure from being drained and you can continue to add
patterns.

The main consequence is that it the assembled pattern will not
undergo any reduction (as the internal data structure undergoes
such a transformation as that it becomes very difficult to cope
with the change that adding a new pattern would bring about. If
this is a problem, the solution is to create a non-mutable object,
continue adding to it as long as needed, and each time a new
assembled regular expression is required, clone the object, turn
the mutable attribute off and proceed as usual.

By default the mutable attribute defaults to zero. The
method can be chained.

  $r->add( 'abcdef\\d+' )->mutable(0);

=cut

sub mutable {
    my $self = shift;
    $self->{mutable} = defined($_[0]) ? $_[0] : 1;
    $self;
}

=item reset

Resets the internal state of the object, as if no C<add> or
C<insert> methods had been called. Does not modify the state
of controller attributes such as C<debug>, C<lex>, C<reduce>
and the like.

=cut

sub reset {
    # reinitialise the internal state of the object
    my $self = shift;
    $self->{path} = [];
    $self->{re}   = undef;
    $self->{str}  = undef;
    $self;
}

=item Default_Lexer

B<Warning:> the C<Default_Lexer> function is a class method, not
an object method. It is a fatal error to call it as an object
method.

The C<Default_Lexer> method lets you replace the default pattern
used for all subsequently created Regexp::Assemble objects. It
will not have any effect on existing objects. (It is also possible
to override the lexer pattern used on a per-object basis).

The parameter should be an ordinary scalar, not a compiled
pattern. If the pattern fails to match all parts of the string,
the missing parts will be returned as single chunks. Therefore
the following pattern is legal (albeit rather cork-brained):

    Regexp::Assemble::Default_Lexer( '\\d' );

The above pattern will split up input strings digit by digit, and
all non-digit characters as single chucks.

=cut

sub Default_Lexer {
    if( $_[0] ) {
        if( my $refname = ref($_[0]) ) {
            croak "Don't pass a $refname to Default_Lexer\n";
        }
        $Default_Lexer = $_[0];
    }
    $Default_Lexer;
}

# --- no user serviceable parts below ---

# -- debug helpers

sub _debug {
    my $self = shift;
    $self->{debug} & shift() ? 1 : 0;
}

# -- helpers

sub _path {
    # access the path
    $_[0]->{path};
}

# -- the heart of the matter

$have_Storable = do {
    eval {
        require Storable;
        import Storable 'dclone';
    };
    $@ ? 0 : 1;
};

sub _path_clone {
    $have_Storable ? dclone($_[0]) : _path_copy($_[0]);
}

sub _path_copy {
    my $path = shift;
    my $new  = [];
    for( my $p = 0; $p < @$path; ++$p ) {
        if( ref($path->[$p]) eq 'HASH' ) {
            push @$new, _node_copy($path->[$p]);
        }
        elsif( ref($path->[$p]) eq 'ARRAY' ) {
            push @$new, _path_copy($path->[$p]);
        }
        else {
            push @$new, $path->[$p];
        }
    }
    $new;
}

sub _node_copy {
    my $node = shift;
    my $new  = {};
    while( my( $k, $v ) = each %$node ) {
        $new->{$k} = defined($v)
            ? _path_copy($v)
            : undef
        ;
    }
    $new;
}

sub _insert_path {
    my $list  = shift;
    my $debug = shift;
    my $in    = shift;
    if( @$list == 0 ) { # special case the first time
        if( @$in == 0 or (@$in == 1 and (not defined $in->[0] or $in->[0] eq ''))) {
            return [{'' => undef}];
        }
        else {
            return $in;
        }
    }
    $debug and print "_insert_path @{[_dump($in)]} into @{[_dump($list)]}\n";
    my $path   = $list;
    my $offset = 0;
    my $token;
    if( not @$in ) {
        if( ref($list->[0]) ne 'HASH' ) {
            return [ { '' => undef, $list->[0] => $list } ];
        }
        else {
            $list->[0]{''} = undef;
            return $list;
        }
    }
    while( defined( $token = shift @$in )) {
        if( ref($token) eq 'HASH' ) {
            $path = _insert_node( $path, $offset, $token, $debug, @$in );
            last;
        }
        if( ref($path->[$offset]) eq 'HASH' ) {
            $debug and print "  at (off=$offset len=@{[scalar @$path]}) ", _dump($path->[$offset]), "\n";
            my $node = $path->[$offset];
            if( exists( $node->{$token} )) {
                $debug and print "  descend key=$token @{[_dump($node->{$token})]}\n";
                $path   = $node->{$token};
                $offset = 0;
                redo;
            }
            else {
                $debug and print "  add path ($token:@{[_dump($in)]}) into @{[_dump($node)]}\n";
                $node->{$token} = [ $token, @$in ];
                last;
            }
        }

        if( $debug ) {
            my $msg = '';
            my $n;
            for( $n = 0; $n < @$path; ++$n ) {
                $msg .= ' ' if $n;
                $msg .= $n == $offset ? "off=<$path->[$n]>" : $path->[$n];
            }
            print " at path ($msg)\n";
        }

        if( $offset >= @$path ) {
            push @$path, { $token => [ $token, @$in ], '' => undef };
            $debug and print "  added remaining @{[_dump($path)]}\n";
            last;
        }
        elsif( $token ne $path->[$offset] ) {
            $debug and print "  token $token not present\n";
            splice @$path, $offset, @$path-$offset, {
                length $token
                    ? ( _node_key($token) => [$token, @$in])
                    : ( '' => undef )
                ,
                $path->[$offset] => [@{$path}[$offset..$#{$path}]],
            };
            last;
        }
        elsif( not @$in ) {
            $debug and print "  last token to add\n";
            if( defined( $path->[$offset+1] )) {
                ++$offset;
                if( ref($path->[$offset]) eq 'HASH' ) {
                    $debug and print "  add sentinel to node\n";
                    $path->[$offset]{''} = undef;
                }
                else {
                    $debug and print "  convert <$path->[$offset]> to node for sentinel\n";
                    splice @$path, $offset, @$path-$offset, {
                        ''               => undef,
                        $path->[$offset] => [ @{$path}[$offset..$#{$path}] ],
                    };
                }
            }
            # nothing at offset+1 => we've already seen this pattern
            last;
        }
        # if we get here then @_ still contains a token
        ++$offset;
    }
    $list;
}

sub _insert_node {
    my $path   = shift;
    my $offset = shift;
    my $token  = shift;
    my $debug  = shift;
    my $path_end = [@{$path}[$offset..$#{$path}]];
    # NB: $path->[$offset] and $[path_end->[0] are equivalent
    my $token_key = _re_path([$token]);
    $debug and print
        " insert node(@{[_dump($token)]}:@{[_dump(\@_)]}) (key=$token_key) at path=@{[_dump($path_end)]}\n";
    if( ref($path_end->[0]) eq 'HASH' ) {
        if( exists($path_end->[0]{$token_key}) ) {
            if( @$path_end > 1 ) {
                my $path_key = _re_path([$path_end->[0]]);
                my $new = {
                    $path_key  => [ @$path_end ],
                    $token_key => [ $token, @_ ],
                };
                $debug and print "  +bifurcate new=@{[_dump($new)]}\n";
                splice( @$path, $offset, @$path_end, $new );
            }
            else {
                my $sub_path = $path_end->[0]{$token_key};
                shift @$sub_path;
                $debug and print "  +_insert_path sub_path=@{[_dump($sub_path)]}\n";
                my $new = _insert_path( $path_end->[0]{$token_key}, $debug, \@_ );
                $path_end->[0]{$token_key} = [$token, @$new];
                $debug and print "  +_insert_path result=@{[_dump($path_end)]}\n";
                splice( @$path, $offset, @$path_end, @$path_end );
            }
        }
        elsif( not _node_eq( $path_end->[0], $token )) {
            if( @$path_end > 1 ) {
                #my $path_key = ref($path_end->[0]) eq 'HASH'
                #    ? _re_path([$path_end->[0]])
                #    : $path_end->[0]
                #;
                my $path_key = _re_path([$path_end->[0]]);
                my $new = {
                    $path_key  => [ @$path_end ],
                    $token_key => [ $token, @_ ],
                };
                $debug and print "  path->node1 at $path_key/$token_key @{[_dump($new)]}\n";
                splice( @$path, $offset, @$path_end, $new );
            }
            else {
                $debug and print "  next in path is node, trivial insert at $token_key\n";
                $path_end->[0]{$token_key} = [$token, @_];
                splice( @$path, $offset, @$path_end, @$path_end );
            }
        }
        else {
            while( @$path_end and _node_eq( $path_end->[0], $token )) {
                $debug and print " identical nodes @{[_dump([$token])]}\n";
                shift @$path_end;
                $token = shift @_;
                ++$offset;
            }
            if( @$path_end ) {
                # coverage shows this condition is never true
                # need to determine why I did this in the first place...
                #if( ref($path->[$offset+1]) eq 'HASH' ) {
                #    $debug and print "  add path into node @{[_dump(\@_)]}\n";
                #    $path->[$offset+1]{$_[0]} = [@_];
                #}
                #else {
                    $debug and print "  insert at $offset $token:@{[_dump(\@_)]} into @{[_dump($path_end)]}\n";
                    my $new = _insert_path( $path_end, $debug, [$token, @_] );
                    splice( @$path, $offset, @$path_end+1, @$new );
                #}
            }
            else {
                $token_key = _node_key($token);
                my $new = {
                    ''         => undef,
                    $token_key => [ $token, @_ ],
                };
                $debug and print "  convert opt @{[_dump($new)]}\n";
                push @$path, $new;
            }
        }
    }
    else {
        if( @$path_end ) {
            my $new = {
                $path_end->[0] => [ @$path_end ],
                $token_key     => [ $token, @_ ],
            };
            $debug and print "  atom->node @{[_dump($new)]}\n";
            splice( @$path, $offset, @$path_end, $new );
        }
        else {
            $debug and print "  add opt @{[_dump([$token,@_])]} via $token_key\n";
            push @$path, {
                ''         => undef,
                $token_key => [ $token, @_ ],
            };
        }
    }
    $path;
}

sub _reduce {
    my $self  = shift;
    my $debug = $self->_debug(DEBUG_TAIL);
    my ($head, $tail) = _reduce_path( $self->_path, $debug, 0 );
    $debug and print "final head=", _dump($head), ' tail=', _dump($tail), "\n";
    if( !@$head ) {
        $self->{path} = $tail;
    }
    else {
        $self->{path} = [
            @{_unrev_path( $tail, $debug, 0 )},
            @{_unrev_path( $head, $debug, 0 )},
        ];
    }
    $debug and print "final path=", _dump($self->{path}), "\n";
    $self;
}

sub _remove_optional {
    if( exists $_[0]->{''} ) {
        delete $_[0]->{''};
        return 1;
    }
    0;
}

sub _reduce_path {
    my ($path, $debug, $depth) = @_;
    my $indent = ' ' x $depth;
    $debug and print "${indent}path $depth in ", _dump($path), "\n";
    my $new;
    my $head = [];
    my $tail = [];
    while( defined( my $p = pop @$path )) {
        if( ref($p) eq 'HASH' ) {
            my ($node_head, $node_tail) = _reduce_node($p, $debug, 1+$depth);
            $debug and print "$indent| head=", _dump($node_head), " tail=", _dump($node_tail), "\n";
            push @$head, @$node_head if scalar @$node_head;
            push @$tail, ref($node_tail) eq 'HASH' ? $node_tail : @$node_tail;
        }
        else {
            if( @$head ) {
                $debug and print "$indent| push $p leaves @{[_dump($path)]}\n";
                push @$tail, $p;
            }
            else {
                $debug and print "$indent| unshift $p\n";
                unshift @$tail, $p;
            }
        }
    }
    if( @$tail > 1
        and ref($tail->[0]) eq 'HASH'
        and exists $tail->[0]{''}
        and keys %{$tail->[0]} == 2
    ) {
        my $path = [@{$tail}[1..$#{$tail}]];
        $tail = $tail->[0];
        ($head, $tail, $path) = _slide_tail( $head, $tail, $path, $debug, 1+$depth );
        $tail = [$tail, @$path];
    }
    $debug and print "${indent}path $depth out head=", _dump($head), ' tail=', _dump($tail), "\n";
    ($head, $tail);
}

sub _reduce_node {
    my ($node, $debug, $depth) = @_;
    my $indent   = ' ' x $depth;
    my $optional = _remove_optional($node);
    $debug and print "${indent}node $depth in @{[_dump($node)]} opt=$optional\n";
    if( $optional and scalar keys %$node == 1 ) {
        my $path = (values %$node)[0];
        if( not grep { ref($_) eq 'HASH' } @$path ) {
            # if we have removed an optional, and there is only one path
            # left then there is nothing left to compare. Because of the
            # optional it cannot participate in any further reductions.
            # (unless we test for equality among sub-trees).
            my $result = {
                ''         => undef,
                $path->[0] => $path
            };
            $debug and print "$indent| fast fail @{[_dump($result)]}\n";
            return [], $result;
        }
    }

    my( $fail, $reduce ) = _scan_node( $node, $debug, 1+$depth );

    $debug and print "$indent: node scan complete opt=$optional reduce=@{[_dump($reduce)]} fail=@{[_dump($fail)]}\n";

    # We now perform tail reduction on each of the nodes in the reduce
    # hash. If we have only one key, we know we will have a successful
    # reduction (since everything that was inserted into the node based
    # on the value of the last token of each path all mapped to the same
    # value).

    if( @$fail == 0 and keys %$reduce == 1 and not $optional) {
        # every path shares a common path
        my $path = (values %$reduce)[0];
        my ($common, $tail) = _do_reduce( $path, $debug, $depth );
        $debug and print "${indent}node $depth out ok common=@{[_dump($common)]} tail=", _dump($tail), "\n";
        return( $common, $tail );
    }

    # this node resulted in a list of paths, game over
    _reduce_fail( $reduce, $fail, $optional, $debug, $depth, $indent );
}

sub _reduce_fail {
    my( $reduce, $fail, $optional, $debug, $depth, $indent ) = @_;
    my %result;
    $result{''} = undef if $optional;
    my $p;
    for $p (keys %$reduce) {
        my $path = $reduce->{$p};
        if( scalar @$path == 1 ) {
            $path = $path->[0];
            $debug and print "$indent| -simple opt=$optional unrev @{[_dump($path)]}\n";
            $path = _unrev_path($path, $debug, 1+$depth);
            $result{_node_key($path->[0])} = $path;
        }
        else {
            $debug and print "$indent| _do_reduce(@{[_dump($path)]})\n";
            my ($common, $tail) = _do_reduce( $path, $debug, 1+$depth );
            $path = [
                (
                    ref($tail) eq 'HASH'
                        ? _unrev_node($tail, $debug, 1+$depth)
                        : _unrev_path($tail, $debug, 1+$depth)
                ),
                @{_unrev_path($common, $debug, 1+$depth)}
            ];
            $debug and print "$indent| +reduced @{[_dump($path)]}\n";
            $result{_node_key($path->[0])} = $path;
        }
    }
    my $f;
    for $f( @$fail ) {
        $debug and print "$indent| +fail @{[_dump($f)]}\n";
        $result{$f->[0]} = $f;
    }
    $debug and print "${indent}node $depth out fail=@{[_dump(\%result)]}\n";
    ( [], \%result );
}

sub _scan_node {
    my( $node, $debug, $depth ) = @_;
    my $indent = ' ' x $depth;

    # For all the paths in the node, reverse them.  If the first token
    # of the path is a scalar, push it onto an array in a hash keyed by
    # the value of the scalar.
    #
    # If it is a node, call _reduce_node on this node beforehand. If we
    # get back a common head, all of the paths in the subnode shared a
    # common tail. We then store the common part and the remaining node
    # of paths (which is where the paths diverged from the end and install
    # this into the same hash. At this point both the common and the tail
    # are in reverse order, just as simple scalar paths are.
    #
    # On the other hand, if there were no common path returned then all
    # the paths of the sub-node diverge at the end character. In this
    # case the tail cannot participate in any further reductions and will
    # appear in forward order.
    #
    # certainly the hurgliest function in the whole file :(

    # $debug = 1 if $depth >= 8;
    my @fail;
    my %reduce;

    my $n;
    for $n(
        map { substr($_, index($_, '#')+1) }
        sort
        map {
            join( '|' =>
                scalar(grep {ref($_) eq 'HASH'} @{$node->{$_}}),
                _node_offset($node->{$_}),
                scalar @{$node->{$_}},
            )
            . "#$_"
        }
    keys %$node ) {
        $debug and print "$indent| off=", _node_offset($node->{$n}),"\n";
        my( $end, @path ) = reverse @{$node->{$n}};
        if( ref($end) ne 'HASH' ) {
            $debug and print "$indent| path=($end:@{[_dump(\@path)]})\n";
            push @{$reduce{$end}}, [ $end, @path ];
        }
        else {
            my( $common, $tail ) = _reduce_node( $end, $debug, 1+$depth );
            if( not @$common ) {
                $debug and print "$indent| +failed $n\n";
                push @fail, [reverse(@path), $tail];
            }
            else {
                my $path = [@path];
                $debug and print "$indent| ++recovered common=@{[_dump($common)]} tail=",
                    _dump($tail), " path=@{[_dump($path)]}\n";
                if( ref($tail) eq 'HASH'
                    and exists $tail->{''}
                    and keys %$tail == 2
                ) {
                    ($common, $tail, $path) =
                        _slide_tail( $common, $tail, $path, $debug, 1+$depth );
                }
                push @{$reduce{$common->[0]}}, [
                    @$common, 
                    (ref($tail) eq 'HASH' ? $tail : @$tail ),
                    @$path
                ];
            }
        }
        $debug and print
            "$indent| counts: reduce=@{[scalar keys %reduce]} fail=@{[scalar @fail]}\n";
    }
    return( \@fail, \%reduce );
}

sub _do_reduce {
    my ($path, $debug, $depth) = @_;
    my $indent = ' ' x $depth;
    my $ra = Regexp::Assemble->new;
    $ra->debug($debug);
    $debug and print "$indent| do @{[_dump($path)]}\n";
    my $p;
    for $p (
        sort {
            scalar(grep {ref($_) eq 'HASH'} @$a)
            <=> scalar(grep {ref($_) eq 'HASH'} @$b)
                ||
            _node_offset($b) <=> _node_offset($a)
                ||
            scalar @$a <=> scalar @$b
        }
        # fucked if I can translate this to an ST
        #map  { $_->[0] }
        #sort { $a->[1] cmp $b->[1] }
        #map  { [$_,
        #    sprintf( '%04d%04d%04d',
        #        scalar(grep {ref($_) eq 'HASH'} @$_),
        #        _node_offset($_),
        #        scalar(@$_)
        #    )]
        #}
        @$path
    ) {
        $debug and print "$indent| add off=@{[_node_offset($p)]} len=@{[scalar @$p]} @{[_dump($p)]}\n";
        $ra->_insertr( $p );
    }
    $path = $ra->_path;
    $debug and print "$indent| path=@{[_dump($path)]}\n";
    my $common = [];
    push @$common, shift @$path while( ref($path->[0]) ne 'HASH' );
    my $tail = scalar( @$path ) > 1 ? [@$path] : $path->[0];
    $debug and print "$indent| common=@{[_dump($common)]} tail=@{[_dump($tail)]}\n";
    ($common, $tail);
}

sub _node_offset {
    # return the offset that the first node is found, or -ve
    # optimised for speed
    my $nr = @{$_[0]};
    my $atom = -1;
    ref($_[0]->[$atom]) eq 'HASH' and return $atom while ++$atom < $nr;
    return -1;
}

sub _slide_tail {
    my $head   = shift;
    my $tail   = shift;
    my $path   = shift;
    my $debug  = shift;
    my $depth  = shift;
    my $indent = ' ' x $depth;
    $debug and print "$indent| slide in h=", _dump($head),
        ' t=', _dump($tail), ' p=', _dump($path), "\n";
    my $slide_path = $tail->{
        # the key that is not ''
        (keys %$tail)[0] ne '' ? (keys %$tail)[0] : (keys %$tail)[1] 
    };
    $debug and print "$indent| slide potential ", _dump($slide_path), " over ", _dump($path), "\n";
    while( defined $path->[0] and $path->[0] eq $slide_path->[0] ) {
        $debug and print "$indent| slide=tail=$slide_path->[0]\n";
        my $slide = shift @$path;
        shift @$slide_path;
        push @$slide_path, $slide;
        push @$head, $slide;
    }
    $debug and print "$indent| slide path ", _dump($slide_path), "\n";
    my $slide_node = {
        '' => undef,
        _node_key($slide_path->[0]) => $slide_path,
    };
    $debug and print "$indent| slide out h=", _dump($head),
        ' s=', _dump($slide_node), ' p=', _dump($path), "\n";
    ($head, $slide_node, $path);
}

sub _unrev_path {
    my ($path, $debug, $depth) = @_;
    my $indent = ' ' x $depth;
    my $new;
    if( not grep { ref($_) } @$path ) {
        $debug and print "${indent}_unrev path fast ", _dump($path);
        $new = [reverse @$path];
        $debug and print " -> ", _dump($new), "\n";
        return $new;
    }
    $debug and print "${indent}unrev path in ", _dump($path), "\n";
    while( defined( my $p = pop @$path )) {
        push @$new, ref($p) eq 'HASH'
            ? _unrev_node($p, $debug, 1+$depth)
            : $p
        ;
    }
    $debug and print "${indent}unrev path out ", _dump($new), "\n";
    $new;
}

sub _unrev_node {
    my ($node, $debug, $depth) = @_;
    my $indent = ' ' x $depth;
    my $optional = _remove_optional($node);
    $debug and print "${indent}unrev node in ", _dump($node), " opt=$optional\n";
    my $new;
    $new->{''} = undef if $optional;
    my $n;
    for $n( keys %$node ) {
        my $path = _unrev_path($node->{$n}, $debug, 1+$depth);
        $new->{_node_key($path->[0])} = $path;
    }
    $debug and print "${indent}unrev node out ", _dump($new), "\n";
    $new;
}

sub _node_key {
    my $node = shift;
    return _node_key($node->[0]) if ref($node) eq 'ARRAY';
    return $node unless ref($node) eq 'HASH';
    my $key = '';
    my $k;
    for $k( keys %$node ) {
        next if $k eq '';
        $key = $k if $key eq '' or $key gt $k;
    }
    $key;
}

#####################################################################

sub _make_class {
    my %set = map { ($_,1) } @_;
    return '.' if exists $set{'.'}
        or (exists $set{'\\d'} and exists $set{'\\D'})
        or (exists $set{'\\s'} and exists $set{'\\S'})
        or (exists $set{'\\w'} and exists $set{'\\W'})
    ;
    for my $meta( q/\\d/, q/\\D/, q/\\s/, q/\\S/, q/\\w/, q/\\W/ ) {
        if( exists $set{$meta} ) {
            my $re = qr/$meta/;
            my @delete;
            $_ =~ /^$re$/ and push @delete, $_ for keys %set;
            delete @set{@delete} if @delete;
        }
    }
    return (keys %set)[0] if keys %set == 1;
    for my $meta( '.', '+', '*', '?', '(', ')', '^', '@', '$', '[', '/', ) {
        exists $set{"\\$meta"} and $set{$meta} = delete $set{"\\$meta"};
    }
    my $dash  = exists $set{'-'} ? do { delete($set{'-'}), '-' } : '';
    my $caret = exists $set{'^'} ? do { delete($set{'^'}), '^' } : '';
    my $class = join( '' => sort keys %set );
    $class =~ s/0123456789/\\d/ and $class eq '\\d' and return $class;
    "[$dash$class$caret]";
}

sub _combine {
    my $type = shift;
    # print "c in = @{[_dump(\@_)]}\n";
    # my $combine = 
    '('
    . $type
    . do {
        my( @short, @long );
        push @{ /^$Single_Char$/ ? \@short : \@long}, $_ for @_;
        if( @short == 1 ) {
            @long = (sort( _re_sort @long ), @short );
        }
        elsif( @short > 1 ) {
            # yucky but true
            my @combine = (_make_class(@short), sort( _re_sort @long ));
            @long = @combine;
        }
        else {
            @long = sort _re_sort @long;
        }
        join( '|', @long );
    }
    . ')';
    # print "combine <$combine>\n";
    # $combine;
}

sub _combine_new {
    my( @short, @long );
    push @{ /^$Single_Char$/ ? \@short : \@long}, $_ for @_;
    if( @short == 1 and @long == 0 ) {
        $short[0];
    }
    elsif( @short > 1 and @short == @_ ) {
        _make_class(@short);
    }
    else {
        '(?:'
            . join( '|' =>
                @short > 1
                    ? ( _make_class(@short), sort(_re_sort @long))
                    : ( (sort _re_sort( @long )), @short )
            )
        . ')';
    }
}

sub _re_path {
    return join( '', @_ ) unless grep { length ref $_ } @_;
    my $in  = shift;
    my $out = '';
    for my $p ( @$in ) {
        if( ref($p) eq '' ) {
            $out .= $p;
        }
        elsif( ref($p) eq 'HASH' ) {
            $out .= _combine_new(
                map { _re_path( $p->{$_} ) }
                grep { $_ ne '' }
                keys %$p
            ) . (exists $p->{''} ? '?' : '');
        }
        else { # ref($p) eq 'ARRAY'
            $out .= _re_path($p);
        }
    }
    $out;
}

sub _lookahead {
    my $in = shift;
    my %head;
    my $path;
    for $path( keys %$in ) {
        next unless defined $in->{$path};
        # print "look $path: ", ref($in->{$path}[0]), ".\n";
        if( ref($in->{$path}[0]) eq 'HASH' ) {
            my $next = 0;
            while( ref($in->{$path}[$next]) eq 'HASH' and @{$in->{$path}} > $next + 1 ) {
                if( exists $in->{$path}[$next]{''} ) {
                    ++$head{$in->{$path}[$next+1]};
                }
                ++$next;
            }
            my $inner = _lookahead( $in->{$path}[0] );
            @head{ keys %$inner } = (values %$inner);
        }
        elsif( ref($in->{$path}[0]) eq 'ARRAY' ) {
            my $subpath = $in->{$path}[0]; 
            for( my $sp = 0; $sp < @$subpath; ++$sp ) {
                if( ref($subpath->[$sp]) eq 'HASH' ) {
                    my $follow = _lookahead( $subpath->[$sp] );
                    @head{ keys %$follow } = (values %$follow);
                    last unless exists $subpath->[$sp]{''};
                }
                else {
                    ++$head{$subpath->[$sp]};
                    last;
                }
            }
        }
        else {
            ++$head{ $in->{$path}[0] };
        }
    }
    # print "_lookahead ", _dump($in), '==>', _dump([keys %head]), "\n";
    \%head;
}

sub _re_path_lookahead {
    my $in  = shift;
    # print "_re_path_la in ", _dump($in), "\n";
    my $out = '';
    for( my $p = 0; $p < @$in; ++$p ) {
        if( ref($in->[$p]) eq '' ) {
            $out .= $in->[$p];
            next;
        }
        elsif( ref($in->[$p]) eq 'ARRAY' ) {
            $out .= _re_path_lookahead($in->[$p]);
            next;
        }
        # print "$p ", _dump($in->[$p]), "\n";
        my $path = [
            map { _re_path_lookahead( $in->[$p]{$_} ) }
            grep { $_ ne '' }
            keys %{$in->[$p]}
        ];
        my $ahead = _lookahead($in->[$p]);
        # print "ref($p): ", ref($in->[$p]), ' ', join( ',' => sort keys %$ahead ), "\n";
        my $more = 0;
        # if( ref($in->[$p]) eq 'HASH' and exists $in->[$p]{''} and $p + 1 < @$in ) {
        if( exists $in->[$p]{''} and $p + 1 < @$in ) {
            my $next = 1;
            while( $p + $next < @$in ) {
                if( ref( $in->[$p+$next] ) eq 'HASH' ) {
                    my $follow = _lookahead( $in->[$p+$next] );
                    @{$ahead}{ keys %$follow } = (values %$follow);
                }
                else {
                    ++$ahead->{$in->[$p+$next]};
                    last;
                }
                ++$next;
            }
            $more = 1;
        }
        my $nr_one = grep { /^$Single_Char$/ } @$path;
        my $nr     = @$path;
        if( $nr_one > 1 and $nr_one == $nr ) {
            $out .= _make_class(@$path);
            $out .= '?' if exists $in->[$p]{''};
        }
        else {
            my $zwla = keys(%$ahead) > 1
                ?  _combine( '?=', grep { s/\+$//; $_ } keys %$ahead )
                : '';
            my $patt = $nr > 1 ? _combine( '?:', @$path ) : $path->[0];
            # print "have nr=$nr n1=$nr_one n=", _dump($in->[$p]), ' a=', _dump([keys %$ahead]), " zwla=$zwla patt=$patt @{[_dump($path)]}\n";
            if( exists $in->[$p]{''} ) {
                $out .=  $more ? "$zwla(?:$patt)?" : "(?:$zwla$patt)?";
            }
            else {
                $out .= "$zwla$patt";
            }
        }
    }
    $out;
}

sub _re_path_track {
    my $self      = shift;
    my $in        = shift;
    my $normal    = shift;
    my $augmented = shift;
    my $o;
    my $simple  = '';
    my $augment = '';
    for( my $n = 0; $n < @$in; ++$n ) {
        if( ref($in->[$n]) eq '' ) {
            $o = $in->[$n];
            $simple  .= $o;
            $augment .= $o;
            if( (
                    $n < @$in - 1
                    and ref($in->[$n+1]) eq 'HASH' and exists $in->[$n+1]{''}
                )
                or $n == @$in - 1
            ) {
                push @{$self->{mlist}}, $normal . $simple ;
                $augment .= "(?{\$self->{m}=$self->{mcount}})";
                ++$self->{mcount};
            }
        }
        else {
            my $path = [
                map { $self->_re_path_track( $in->[$n]{$_}, $normal.$simple , $augmented.$augment ) }
                grep { $_ ne '' }
                keys %{$in->[$n]}
            ];
            $o = '(?:' . join( '|' => sort _re_sort @$path ) . ')';
            $o .= '?' if exists $in->[$n]{''};
            $simple  .= $o;
            $augment .= $o;
        }
    }
    $augment;
}

sub _re_path_pretty {
    my $in  = shift;
    my $arg = shift;
    my $pre    = ' ' x (($arg->{depth}+0) * $arg->{indent});
    my $indent = ' ' x (($arg->{depth}+1) * $arg->{indent});
    my $out = '';
    $arg->{depth}++;
    my $prev_was_paren = 0;
    for( my $p = 0; $p < @$in; ++$p ) {
        if( ref($in->[$p]) eq '' ) {
            $out .= "\n$pre" if $prev_was_paren;
            $out .= $in->[$p];
            $prev_was_paren = 0;
        }
        elsif( ref($in->[$p]) eq 'ARRAY' ) {
            $out .= _re_path($in->[$p]);
        }
        else {
            my $path = [
                map { _re_path_pretty( $in->[$p]{$_}, $arg ) }
                grep { $_ ne '' }
                keys %{$in->[$p]}
            ];
            my $nr     = @$path;
            my $nr_one = grep { length($_) == 1 } @$path;
            if( $nr_one == $nr ) {
                # $out .= "\n$pre" if $prev_was_paren;
                $out .=  $nr == 1 ? $path->[0] : _make_class(@$path);

                $out .= '?' if exists $in->[$p]{''};
                # $prev_was_paren = 0;
            }
            else {
                $out .= "\n" if length $out;
                # apparently $prev_was_paren can never be true
                # here, according to Devel::Cover, and assuming
                # I've covered all the possibilities.
                # $out .= $pre if $p or $prev_was_paren;
                $out .= $pre if $p;
                $out .= "(?:\n$indent";
                if( $nr_one < 2 ) {
                    my $r = 0;
                    $out .= join( "\n$indent|" => map {
                            $r++ and $_ =~ s/^\(\?:/\n$indent(?:/;
                            $_
                        }
                        sort _re_sort @$path
                    );
                }
                else {
                    $out .= do {
                            my( @short, @long );
                            # push @{length $_ > 1 ? \@long : \@short}, $_ for @$path;
                            push @{/^$Single_Char$/ ? \@short : \@long}, $_ for @$path;
                            join( "\n$indent|" => ( sort( _re_sort @long ), _make_class(@short) ));
                        }
                    ;
                }
                $out .= "\n$pre)";
                if( exists $in->[$p]{''} ) {
                    $out .= "\n$pre?";
                    $prev_was_paren = 0;
                }
                else {
                    $prev_was_paren = 1;
                }
            }
        }
    }
    $arg->{depth}--;
    $out;
}

sub _re_sort {
    length $b <=> length $a || $a cmp $b
}

sub _node_eq {
    return 0 if not defined $_[0] or not defined $_[1];
    return 0 if ref $_[0] ne ref $_[1];
    # Now that we have determined that the reference of each
    # argument are the same, we only have to test the first
    # one, which gives us a nice micro-optimisation.
    if( ref($_[0]) eq 'HASH' ) {
        keys %{$_[0]} == keys %{$_[1]}
            and
        # does this short-circuit to avoid _re_path() cost more than it saves?
        join( '|' => sort keys %{$_[0]}) eq join( '|' => sort keys %{$_[1]})
            and
        _re_path( [$_[0]] ) eq _re_path( [$_[1]] );
    }
    elsif( ref($_[0]) eq 'ARRAY' ) {
        scalar @{$_[0]} == scalar @{$_[1]}
            and
        _re_path($_[0]) eq _re_path($_[1]);
    }
    else {
        $_[0] eq $_[1];
    }
}

sub _dump {
    my $path = shift;
    return _dump_node($path) if ref($path) eq 'HASH';
    my $dump = '[';
    my $d;
    my $nr = 0;
    for $d( @$path ) {
        $dump .= ' ' if $nr++;
        if( ref($d) eq 'HASH' ) {
            $dump .= _dump_node($d);
        }
        elsif( ref($d) eq 'ARRAY' ) {
            $dump .= _dump($d);
        }
        elsif( defined $d ) {
            # D::C indicates the second test is redundant
            # $dump .= ( $d =~ /\s/ or not length $d )
            $dump .= ( $d =~ /\s/ )
                ? qq{'$d'}
                :     $d
            ;
        }
        else {
            $dump .= '*';
        }
    }
    $dump . ']';
}

sub _dump_node {
    my $node = shift;
    my $dump = '{';
    my $nr   = 0;
    my $n;
    for $n (sort keys %$node) {
        $dump .= ' ' if $nr++;
        # Devel::Cover shows this to test to be redundant
        # $dump .= ( $n eq '' and not defined $node->{$n} )
        $dump .= $n eq ''
            ? '*'
            : "$n=>" . _dump($node->{$n})
        ;
    }
    $dump . '}';
}

=back

=head1 DIAGNOSTICS

"don't pass a C<refname> to Default_Lexer"

You tried to replace the default lexer pattern with an object
instead of a scalar. Solution: You probably tried to call
$obj->Default_Lexer. Call qualified class method instead
C<Regexp::Assemble::Default_Lexer>.

"filter method not passed a coderef"

A reference to a subroutine (anonymous or otherwise) was expected.
Solution: read the documentation for the C<filter> method.

=head1 NOTES

This module has been tested successfully with a range of versions
of perl, from 5.005_03 to 5.9.2. Use of 5.6.0 is not recommended.

The expressions produced by this module can be used with the PCRE
library.

Where possible, supply the simplest tokens possible. Don't add
C<X(?-\d+){2})Y> when C<X-\d+-\d+Y> will do. The reason is that
if you also add C<X\d+Z> the resulting assembly changes
dramatically: C<X(?:(?:-\d+){2}Y|-\d+Z)> I<versus>
C<X-\d+(?:-\d+Y|Z)>.  Since R::A doesn't analyse tokens, it
doesn't "unroll" the C<{2}> quantifier, and will fail to notice
the divergence after the first C<-d\d+>.

What is more, when the string 'X-123000P' is matched against the
first assembly, the regexp engine will have to backtrack over each
alternation (the one that ends in Y B<and> the one that ends in Z)
before determining that there is no match. No such backtracking
occurs in the second pattern: as soon as the engine encounters the
'P' in the target string, neither of the alternations at that point
(C<-\d+Y> or C<Z>) succeed and the match fails.

C<Regexp::Assemble> does, however, know how to build character
classes. Given C<a-b>, C<axb> and C<a\db>, it will assemble these
into C<a[-\dx]b>.  When C<-> (dash) appears as a candidate for a
character class it will be the first character in the class.  When
C<^> (circumflex) appears as a candidate for a character class it
will be the last character in the class.

It also knows about meta-characters than can "absorb" regular
characters. For instance, given C<X\d> and C<X5>, it knows that C<5>
can be represented by C<\d> and so the assembly is just C<X\d>. The
"absorbent" meta-characters it deals with are C<.>, C<\d>, C<\s>
and C<\W> and their complements. It also knows that C<\d> and C<\D>
(and similar pairs) can be replaced by C<.>.

C<Regexp::Assemble> deals correctly with C<quotemeta>'s propensity
to backslash many characters that have no need to be. Backslashes on
non-metacharacters will be removed. Similarly, in character classes,
a number of characters lose their magic and so no longer need to be
backslashed within a character class. Two common examples are C<.>
(dot) and C<$>. Such characters will lose their backslash.

At the same time, it will also process C<\Q...\E> sequences. When
such a sequence is encountered, the inner section is extracted and
C<quotemeta> is applied to the section. The resulting quoted text
is then used in place of the original unquoted text, and the C<\Q>
and C<\E> metacharacters are thrown awa. Similar processing occurs
with the C<\U...\E> and C<\L...\E> sequences.

C<Regexp::Assemble> will also replace all the digits 0..9 appearing
in a character class by C<\d>. I'd do it for letters as well, but
thinking about accented characters and other glyphs hurts my head.

In an alternation, the longest paths are chosen first (I<e.g.>
C<horse|bird|dog>). When two paths have the same length,
the path with the most subpaths will appear first. This aims to
put the "busiest" paths to the front of the alternation. I<E.g.>,
the list C<bad>, C<bit>, C<few>, C<fig> and C<fun> will produce
the pattern C<(?:f(?:ew|ig|un)|b(?:ad|it))>.

When tracking is in use, no reduction is performed. Furthermore,
no character classes are formed. The reason is that it becomes just
too difficult to determine the original pattern.  Consider the the
two patterns C<pale> and C<palm>. These would be reduced to
C<(?:pal[em]>. The final character matches one of two possibilities.
To resolve whether it matched an C<'e'> or C<'m'> would require a
whole lot more housekeeping. Without character classes it becomes
much easier.

Similarly, C<dogfood> and C<seafood> would form C<(?:dog|sea)food>.
When the pattern is being assembled, the tracking decision needs
to be made at the end of the grouping, but the tail of the pattern
has not yet been visited. Deferring things to make this work correctly
is a vast hassle. Tracked patterns will therefore be bulkier than
simple patterns.

There is an open bug on this issue:

L<http://rt.perl.org/rt3/Ticket/Display.html?id=32840>

If this bug is ever resolved, tracking would become much easier
to deal with (none of the C<match> hassle would be required - you could
just match like a regular RE and it would Just Work).

=head1 SEE ALSO

=over 8

=item L<perlre>

General information about Perl's regular expressions.

=item L<re>

Specific information about C<use re 'eval'>.

=item Regex::PreSuf

C<Regex::PreSuf> takes a string and chops it itself into tokens of
length 1. Since it can't deal with tokens of more than one character,
it can't deal with meta-characters and thus no regular expressions.
Which is the main reason why I wrote this module.

=item Regexp::Optimizer

C<Regexp::Optimizer> produces regular expressions that are similar to
those produced by R::A with reductions switched off. It's biggest
drawback is that it is exponentially slower than Regexp::Assemble on
very large sets of patterns.

=item Text::Trie

C<Text::Trie> is well worth investigating. Tries can outperform very
bushy (read: many alternations) patterns.

=back

=head1 LIMITATIONS

C<Regexp::Assemble> does not attempt to find common substrings. For
instance, it will not collapse C</cabababc/> down to C</c(?:ab){3}c/>.
If there's a module out there that performs this sort of string
analysis I'd like to know about it. But keep in mind that the
algorithms that do this are very expensive: quadratic or worse.

C<Regexp::Assemble> does not interpret meta-character modifiers.
For instance, if the following two patterns are
given: C<X\d> and C<X\d+>, it will not determine that C<\d> can be
matched by C<\d+>. Instead, it will produce C<X(?:\d|\d+)>. Along
a similar line of reasoning, it will not determine that C<Z> and
C<Z\d+> is equivalent to C<Z\d*> (It will produce C<Z(?:\d+)?>
instead).

You can't remove a pattern that has been added to an object. You'll
just have to start over again. Adding a pattern is difficult enough,
I'd need a solid argument to convince me to add a C<remove> method.
If you need to do this you should read the documentation on the
C<mutable> and C<clone> methods.

Tracking doesn't really work at all with 5.6.0. It works better
in subsequent 5.6 releases. For maximum reliability, the use of
a 5.8 release is strongly recommended.

C<Regexp::Assemble> does not (yet)? employ the C<(?E<gt>...)>
construct.

The module does not produce POSIX-style regular expressions. This
would be quite easy to add, if there was a demand for it.

=head1 BUGS

The algorithm used to assemble the regular expressions makes extensive
use of mutually-recursive functions (I<i.e.>: A calls B, B calls A,
...) For deeply similar expressions, it may be possible to provoke
"Deep recursion" warnings.

The module has been tested extensively, and has an extensive test
suite (that achieves 100% statement coverage), but you never know...
A bug may manifest itself in two ways: creating a pattern that cannot
be compiled, such as C<a\(bc)>, or a pattern that compiles correctly
but that either matches things it shouldn't, or doesn't match things
it should. It is assumed that Such problems will occur when the reduction
algorithm encounters some sort of edge case. A temporary work-around
is to disable reductions:

  my $pattern = $assembler->reduce(0)->re;

A discussion about implementation details and where bugs might lurk
appears in the README file. If this file is not available locally,
you should be able to find a copy on the Web at your nearest CPAN
mirror.

Seriously, though, a number of people have been using this module to
create expressions anywhere from 140Kb to 600Kb in size, and it seems to
be working according to spec. Thus, I don't think there are any serious
bugs remaining.

If you are feeling brave, extensive debugging traces are available.

Please report all bugs at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Regexp-Assemble|rt.cpan.org>

Make sure you include the output from the following two commands:

  perl -MRegexp::Assemble -le 'print Regexp::Assemble::VERSION'
  perl -V

There is a mailing list for the discussion of C<Regexp::Assemble>.
Subscription details are available at
L<http://www.mongueurs.net/mailman/Regexp::Assemble>.

=head1 ACKNOWLEDGEMENTS

This module grew out of work I did building access maps for Postfix,
a modern SMTP mail transfer agent. See L<http://www.postfix.org/>
for more information.  I used Perl to build large regular expressions
for blocking dynamic/residential IP addresses to cut down on spam
and viruses. Once I had the code running for this, it was easy to
start adding stuff to block really blatant spam subject lines, bogus
HELO strings, spammer mailer-ids and more...

I presented the work at the French Perl Workshop in 2004, and the
thing most people asked was whether the underlying mechanism for
assembling the REs was available as a module. At that time it was
nothing more that a twisty maze of scripts, all different. The
interest shown indicated that a module was called for. I'd like to
thank the people who showed interest. Hey, it's going to make I<my>
messy scripts smaller, in any case.

Thomas Drugeon has been a valuable sounding board for trying out
new ideas. Jean Forget and Philippe Blayo looked over an early
version. H. Merijn Brandt stopped over in Paris one evening, and
discussed things over a few beers.

Nicholas Clark pointed out that while what this module does
(?:c|sh)ould be done in perl's core, as per the 2004 TODO, he
encouraged to me continue with the development of this module. In
any event, this module allows one to gauge the difficulty of
undertaking the endeavour in C. I'd rather gouge my eyes out with
a blunt pencil.

Paul Johnson settled the question as to whether this module should
live in the Regex:: namespace, or Regexp:: namespace.  If you're
not convinced, try running the following one-liner:

  perl -le 'print ref qr//'

Thanks also to broquaint on Perlmonks, who answered a question
pertaining to traversing an early version of the underlying data
structure used by the module (Sadly, that code is no more). bart
and ysth also provided a couple of tips pertaining to the Correct
Use of overloading.

=head1 AUTHOR

David Landgren, david@landgren.net

Copyright (C) 2004-2005.
All rights reserved.

http://www.landgren.net/perl/

If you use this module, I'd love to hear about what you're using
it for. If you want to be informed of updates, send me a note.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

'The Lusty Decadent Delights of Imperial Pompeii';
__END__
