# Regexp::Assemple.pm
#
# Copyright (c) 2004 David Landgren, all rights reserved

package Regexp::Assemble;

use vars qw/$VERSION $have_Storable $Default_Lexer/;
$VERSION = '0.05';

=head1 NAME

Regexp::Assemble - Assemble multiple Regular Expressions into one RE

=head1 VERSION

This document describes version 0.05 of Regexp::Assemble,
released 2004-12-10.

=head1 SYNOPSIS

  use Regexp::Assemble;
  
  my $ra = Regexp::Assemble->new;
  $ra->add( 'ab+c' );
  $ra->add( 'ab+\\d*\\s+c' );
  $ra->add( 'a\\w+\\d+' );
  $ra->add( 'a\\d+' );
  print $ra->re; # prints (?:a(?:b+(?:\d*\s+)?c|(?:\w+)?\d+))

=head1 DESCRIPTION

Regexp::Assemble takes a number of regular expressions and assembles
them into a single regular expression (or RE) that matches all that
the individual REs match, only what they match and nothing else.

The assembled RE is more sophisticated than a brute force C<join(
'|', @list)> concatenation. Common subexpressions are shared;
alternations are introduced only when patterns diverge. As a result,
backtracking is kept to a minimum. If a given path fails... there
are no other paths to try and so the expression fails quickly. If
no wildcards like C<.*> appear, no backtracking will be performed.
In very large expressions, this can provide a large speed boost.

As a result, instead of having a large list of expressions to loop
over, the string only needs to be tested against one expression.
This is especially interesting when on average the expression fails
to match most of the time.

This is useful when you have a large number of patterns that you
want to apply against a string. If you only that one of the
patterns matched then this module is for you. Nonetheless, large
numbers of alternations are dealt with in O(n) time, not O(1). If
you are still having performance problems, you should look at using
a trie.

Some more examples of usage appear in the accompanying README.

=cut

use strict;
use Carp 'croak';

use constant DEBUG_ADD     => 1;
use constant DEBUG_TAIL    => 2;

# The following pattern was generated using naive.pl and pasted in here
$Default_Lexer = qr/(?:\\[bluABCEGLQUXZ]|(?:\\[aefnrtdDwWsS.+*?]|\\0\d{2}|\\x(?:[\da-fA-F]{2}|{[\da-fA-F]{4}})|\\c.|\\N{\w+}|\\[Pp](?:.|{\w+})|\[.*?(?<!\\)\]|\(.*?(?<!\\)\)|.)(?:(?:[*+?]|\{\d+(?:,\d*)?\})\??)?)/;

=head1 METHODS

=over 8

=item new

Creates a new Regexp::Assemble object. A set of key/value parameters
can be supplied to control the finer details of the object's
behaviour.

B<chomp>, controls whether the pattern should be chomped before being
lexed. Handy if you are reading lines from a file. By default, no
chomping is performed.

B<filter>, allows you to add a callback to enable sanity checks on
the pattern being loaded.

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
        re      => undef,
        str     => undef,
        lex     => exists $args{lex}     ? qr/$args{lex}/ : qr/$Default_Lexer/,
        chomp   => exists $args{chomp}   ? $args{chomp}   : 0,
        reduce  => exists $args{reduce}  ? $args{reduce}  : 1,
        mutable => exists $args{mutable} ? $args{mutable} : 0,
        debug   => exists $args{debug}   ? $args{debug}   : 0,
        filter  => $args{filter}, # don't care if it's not there
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
        re      => $self->{re},
        str     => $self->{str},
        lex     => $self->{lex},
        chomp   => $self->{chomp},
        reduce  => $self->{reduce},
        mutable => $self->{mutable},
        debug   => $self->{debug},
        path    => _path_clone($self->_path),
    };
    bless $clone, ref($self);
}

=item add(LIST)

Takes a string, breaks it apart into a set of tokens (respecting
meta characters) and inserts the resulting list into the C<R::A>
object. It uses a naive regular expression to lex the string
that may be fooled complex expressions (specifically, it will
fail to lex nested parenthetical expressions such as
C<ab(?cd(?:ef)?gh)> correctly). If this is the case, the end of
the string will not be tokenised correctly and returned as one
long string.

On the one hand, this may indicate that the patterns you are
trying to feed the C<R::A> object are too complex. Simpler
patterns might allow the algorithm to work more effectively and
spot reductions in the resulting pattern.

On the other hand, you can supply your own pattern to perform the
lexing if you need, and if that is not enough, you can provide a
code block for the ultimate in lexing flexibility.

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

This method is chainable.

=cut

sub _lex {
    my $self   = shift;
    my $record = shift;
    my @path   = ();
    while( $record =~  s/($self->{lex})// ) {
        length($1) or croak
            "lexed a zero-length token, an infinite loop would ensue\nlex=$self->{lex}\nrecord=$record\n";
        push @path, $1;
    }
    push @path, $record if length($record);
    @path;
}

sub add {
    my $self = shift;
    my $record;
    while( defined( $record = pop @_ )) {
        chomp($record) if $self->{chomp};
        $self->insert( $self->_lex($record) );
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

=cut

sub insert {
    my $self = shift;
    my $debug = $self->_debug(DEBUG_ADD);
    return $self if $self->{filter} and not $self->{filter}->(@_);
    $self->{path} = _insert_path( $self->_path, $debug, @_ );
    $self->{str}  = $self->{re} = undef;
    $self;
}

=item as_string

Assemble the expression and return it as a string. You may want to do this
if you are writing the pattern to a file. The following arguments can be
passed to control the aspect of the resulting pattern:

B<indent>, the number of spaces used to indent nested grouping of
a pattern. Use this to produce a pretty-printed pattern (for some
definition of "pretty"). The resulting output is rather verbose. The
reason is to ensure that the metacharacters C<(?:> and C<)> always
occur on otherwise empty lines. This allows you grep the result for an
even more synthetic view of the pattern:

  egrep -v '^ *[()]' <regexp.file>

The result of the above is quite readable. Remember to backslash the
spaces appearing in your own patterns if you wish to use an indented
pattern in an C<m/.../x> construct.

If you have not set the B<mutable> attribute on the object, calling this
method will drain the internal data structure. Large numbers of patterns
can eat a significant amount of memory, and this lets perl recover the
memory used. Mutable means that you want to keep the internal data
structure lying around in order to add additional patterns to the object
after an assembled pattern has been produced.

=cut

sub as_string {
    my $self = shift;
    if( not defined $self->{str} ) {
        $self->_reduce if not $self->{mutable} and $self->{reduce};
        my $arg  = {@_};
        if( exists $arg->{indent} and $arg->{indent} > 0 ) {
            $arg->{depth} = 0;
            $self->{str}  = _re_path_pretty($self->_path, $arg);
        }
        else {
            $self->{str}  = _re_path($self->_path);
        }
        $self->{path} = [] unless $self->{mutable};
    }
    # if no string, do not match anything
    $self->{str} || '^a\bz';
}

=item re

Assembles the pattern and return it as a compiled RE, using the C<qr//>
operator. Note that there is no way of specifying flags to the qr
operator. If you need to do something fancy, then you should retrieve
the string using the B<as_string> operator and apply the required
C<qr//imx>-type flags yourself.

The B<indent> attribute, documented in the C<as_string> method can be
used here.

As with C<as_string>, calling this method will reset the internal data
structures to free the memory used in assembling the RE. This behaviour
can be controlled with the C<mutable> attribute.

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

Note that when a C<Regexp::Assemble> object is used in string context
(hence, within an C<m//> operator), the C<re> method is called, so
you don't even need to save the RE in a separate variable. The
following will work as expected:

  my $re = Regexp::Assemble->new->add( qw[ fee fie foe fum ] );
  while( <IN> ) {
    if( /($re)/ ) {
      print "Here be giants: $1\n";
    }
  }

=cut

sub re {
    my $self = shift;
    if( not defined $self->{re} ) {
        my $re = $self->as_string(@_);
        $self->{re} = qr/$re/;
    }
    $self->{re};
}

# strip off the garbage that overloading wishes to provide us.
# see perldoc overload, section " Calling Conventions for Unary
# Operations". Credit to [bart] on the Perlmonks chatterbox for
# showing me this technique.

use overload '""' => sub { $#_ = 0; goto &re };

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
dealing with the reduction of the assembled pattern.

Values can be added (or or'ed together) to trace everything

   $r->debug(1)->add( '\\d+abc' );

=cut

sub debug {
    my $self = shift;
    $self->{debug} = defined($_[0]) ? $_[0] : 0;
    $self;
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

=item filter(CODE)

Allows you to install a callback to check that the pattern
being loaded contains valid input. It receives a list on
input. It is expected to return 0 to indicate that the
pattern should not be added, anything else indicates
that the contents are fine.

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
and so forth.

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
an object method. Do not call it on an object, bad things will
happen.

  Regexp::Assemble::Default_Lexer( '.|\\d+' );

The C<Default_Lexer> method lets you replace the default pattern
used for all subsequently created Regexp::Assemble objects. It
will not have any effect on existing objects. (It is also possible
to override the lexer pattern used on a per-object basis).

The parameter should be an ordinary scalar, not a compiled
pattern. The pattern should be capable of matching all parts of
the string, I<i.e.>, the following constraint should hold true:

  $_ = 'this will be matched by a pattern';
  my $pattern = qr/./;
  my @token = m/($pattern)/g;
  $_ eq join( '' => @token ) or die;

If no parameter is supplied, the current default pattern in use
will be returned.

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
    $have_Storable
        ? dclone($_[0])
        : _path_copy($_[0]);
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
    print "_insert_path @{[_dump(\@_)]} into @{[_dump($list)]}\n" if $debug;
    my $path   = $list;
    my $offset = 0;
    my $token;
    while( defined( $token = shift @_ )) {
        if( ref($token) eq 'HASH' ) {
            $path = _insert_node( $path, $offset, $token, $debug, @_ );
            last;
        }
        if( ref($path->[$offset]) eq 'HASH' ) {
            $debug and print "  at (off=$offset len=@{[scalar @$path]}) ",
                _dump_node($path->[$offset]), "\n";
            my $node = $path->[$offset];
            if( exists( $node->{$token} )) {
                print "  descend key=$token @{[_dump($node->{$token})]}\n" if $debug;
                $path   = $node->{$token};
                $offset = 0;
                redo;
            }
            else {
                print "  add path ($token:@{[_dump([@_])]}\n" if $debug;
                $node->{$token} = [$token, @_];
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
        if( not @$path ) {
            print "  add remaining @{[_dump([$token,@_])]}\n" if $debug;
            push @$path, length $token ? ($token, @_) : {'' => undef};
            last;
        }
        elsif( $offset >= @$path ) {
            print "  path ends\n" if $debug;
            push @$path, { $token => [ $token, @_ ], '' => undef, };
            last;
        }
        elsif( $token ne $path->[$offset] ) {
            if( @_ or length $token ) {
                my $key = ref($token) eq 'HASH' ? _node_key($token) : $token;
                splice @$path, $offset, @$path-$offset, {
                    $key             => [$token, @_],
                    $path->[$offset] => [@{$path}[$offset..$#{$path}]],
                }
            }
            else {
                splice @$path, $offset, @$path-$offset, {
                    ''               => undef,
                    $path->[$offset] => [@{$path}[$offset..$#{$path}]],
                };
            }
            last;
        }
        elsif( not @_ ) {
            print "  last token to add\n" if $debug;
            if( defined( $path->[$offset+1] )) {
                ++$offset;
                if( ref($path->[$offset]) eq 'HASH' ) {
                    print "  add sentinel to node\n" if $debug;
                    $path->[$offset]{''} = undef;
                }
                else {
                    print "  convert <$path->[$offset]> to node for sentinel\n" if $debug;
                    splice @$path, $offset, @$path-$offset, {
                        ''               => undef,
                        $path->[$offset] => [ @{$path}[$offset..$#{$path}] ],
                    };
                }
                last;
            }
        }
        # if we get here then @_ still contains a token
    }
    continue {
        ++$offset;
    }
    print "    := @{[_dump($list)]}\n" if $debug;
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
        " insert node(@{[_dump_node($token)]}:@{[_dump([@_])]}) (key=$token_key) at path=@{[_dump($path_end)]}\n";
    if( ref($path_end->[0]) eq 'HASH' ) {
        $debug and print 'pe=', _dump($path_end),"\n";
        $debug and print 'to=', _dump([$token]),"\n";
        $debug and print '@_=', _dump([@_]),"\n";
        if( exists($path_end->[0]{$token_key}) ) {
            my $sub_path = $path_end->[0]{$token_key};
            shift @$sub_path;
            print "  +_insert_path sub_path=@{[_dump([$sub_path])]}\n"
                if $debug;
            my $new = _insert_path( $path_end->[0]{$token_key}, $debug, @_ );
            $path_end->[0]{$token_key} = [$token, @$new];
            print "  +_insert_path result=@{[_dump($path_end)]}\n" if $debug;
            splice( @$path, $offset, @$path_end, @$path_end );
        }
        elsif( not _node_eq( $path_end->[0], $token )) {
            if( @$path_end > 1 ) {
                my $path_key = ref($path_end->[0]) eq 'HASH'
                    ? _re_path([$path_end->[0]])
                    : $path_end->[0]
                ;
                my $new = {
                    $path_key  => [ @$path_end ],
                    $token_key => [ $token, @_ ],
                };
                print "  path->node1 at $path_key/$token_key @{[_dump_node($new)]}\n"
                    if $debug;
                splice( @$path, $offset, @$path_end, $new );
            }
            else {
                print "  next in path is node, trivial insert at $token_key\n" if $debug;
                $path_end->[0]{$token_key} = [$token, @_];
                splice( @$path, $offset, @$path_end, @$path_end );
            }
        }
        else {
            while( @$path_end and _node_eq( $path_end->[0], $token )
            ) {
                print " identical nodes @{[_dump([$token])]}\n"
                    if $debug;
                shift @$path_end;
                $token = shift @_;
                ++$offset;
            }
            if( @$path_end ) {
                if( ref($path->[$offset+1]) eq 'HASH' ) {
                    print "  add path into node @{[_dump([@_])]}\n"
                        if $debug;
                    $path->[$offset+1]{$_[0]} = [@_];
                }
                else {
                    my $new = _insert_path( $path_end, $debug, $token, @_ );
                    print "  convert @{[_dump($new)]}\n" if $debug;
                    splice( @$path, $offset, @$path_end+1, @$new );
                }
            }
            else {
                $token_key = _node_key($token);
                my $new = {
                    ''         => undef,
                    $token_key => [ $token, @_ ],
                };
                print "  convert opt @{[_dump_node($new)]}\n" if $debug;
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
            print "  atom->node @{[_dump_node($new)]}\n"
                if $debug;
            splice( @$path, $offset, @$path_end, $new );
        }
        else {
            print "  add opt @{[_dump([$token,@_])]} via $token_key\n"
                if $debug;
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
    print "final head=", _dump($head), ' tail=', _dump($tail), "\n"
        if $debug;
    if( !@$head ) {
        $self->{path} = $tail;
    }
    else {
        my @path = (
            @{_unrev_path( $tail, $debug, 0 )},
            @{_unrev_path( $head, $debug, 0 )},
        );
        $self->{path} = \@path;
    }
    print "final path=", _dump($self->{path}), "\n/", _re_path($self->{path}), "/\n" if $debug;
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
    print "${indent}path $depth in ", _dump($path), "\n" if $debug;
    my $new;
    my $head = [];
    my $tail = [];
    while( defined( my $p = pop @$path )) {
        if( ref($p) eq 'HASH' ) {
            my ($node_head, $node_tail) = _reduce_node($p, $debug, 1+$depth);
            print "$indent| head=", _dump($node_head), " tail=", _dump([$node_tail]), "\n"
                if $debug;
            push @$head, @$node_head if scalar @$node_head;
            push @$tail, ref($node_tail) eq 'HASH' ? $node_tail : @$node_tail;
        }
        else {
            if( @$head ) {
                print "$indent| push $p leaves @{[_dump($path)]}\n" if $debug;
                push @$tail, $p;
            }
            else {
                print "$indent| unshift $p\n" if $debug;
                unshift @$tail, $p;
            }
        }
    }
    if( @$tail > 1
        and ref($tail->[0]) eq 'HASH'
        and exists $tail->[0]{''}
        and keys %{$tail->[0]} == 2
    ) {
        # not quite
        # ($head, $tail, $path) = _slide_tail( $head, $tail, $path, $debug, 1+$depth );
        my $slide_node = shift @$tail;
        print "$indent| [x]try to slide", _dump_node($slide_node), "\n" if $debug;
        my $slide_path;
        my $s;
        # get the key that is not ''
        while( $s = each %$slide_node ) {
            if( $s ) {
                $slide_path = $slide_node->{$s};
                last;
            }
        }
        print "$indent| [x]slide potential ", _dump($slide_path), " over ",
            _dump($tail), "\n"
                if $debug;
        while( $slide_path->[0] eq $tail->[0] ) {
            print "$indent| [x]slide=$slide_path->[0] eq tail=$tail->[0] ok\n" if $debug;
            my $slide = shift @$tail;
            shift @$slide_path;
            push @$slide_path, $slide;
            push @$head, $slide;
        }
        $slide_node = { '' => undef, $slide_path->[0] => $slide_path };
        print "$indent| [x]slide final ", _dump_node($slide_node), "\n"
            if $debug;
        unshift @$tail, $slide_node;
    }
    print "${indent}path $depth out head=", _dump($head), ' tail=', _dump($tail), "\n"
        if $debug;
    ($head, $tail);
}

sub _reduce_node {
    my ($node, $debug, $depth) = @_;
    my $indent   = ' ' x $depth;
    my $optional = _remove_optional($node);
    print "${indent}node $depth in @{[_dump_node($node)]} opt=$optional\n"
        if $debug;
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
            $debug and print "$indent| fast fail @{[_dump_node($result)]}\n";
            return [], $result;
        }
    }

    my( $fail, $reduce ) = _scan_node( $node, $debug, 1+$depth );

    print "$indent: node scan complete opt=$optional reduce=@{[_dump_node($reduce)]} fail=@{[_dump($fail)]}\n"
        if $debug;

    # We now perform tail reduction on each of the nodes in the reduce
    # hash. If we have only one key, we know we will have a successful
    # reduction (since everything that was inserted into the node based
    # on the value of the last token of each path all mapped to the same
    # value).

    if( @$fail == 0 and keys %$reduce == 1 and not $optional) {
        # every path shares a common path
        my $path = (values %$reduce)[0];
        my ($common, $tail) = _do_reduce( $path, $debug, $depth );
        if( $debug ) {
            print "${indent}node $depth out ok c=@{[_dump($common)]} ";
            if( ref($tail) eq 'HASH' ) {
                print "t=@{[_dump_node($tail)]}\n"
            }
            else {
                print "t=@{[_dump($tail)]}\n"
            }
        }
        return( $common, $tail );
    }

    # this node results in a list of paths, game over
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
            my $key  = $path->[0];
            print "$indent| -simple opt=$optional key=$key @{[_dump($path)]}\n" if $debug;
            $path =  _unrev_path($path, $debug, 1+$depth);
            $key = $path->[0] unless ref($path->[0] eq 'HASH');
            $result{$key} = $path;
        }
        else {
            print "$indent| -reduce @{[_dump($path)]}\n" if $debug;
            my ($common, $tail) = _do_reduce( $path, $debug, 1+$depth );
            $path = [
                (
                    ref($tail) eq 'HASH'
                        ? _unrev_node($tail, $debug, 1+$depth)
                        : _unrev_path($tail, $debug, 1+$depth)
                ),
                @{_unrev_path($common, $debug, 1+$depth)}
            ];
            my $key = ref($path->[0]) eq 'HASH' ? _node_key($path->[0]) : $path->[0];
            print "$indent| -reduced key=<$key> @{[_dump($path)]}\n" if $debug;
            $result{$key} = $path;
        }
    }
    my $f;
    for $f( @$fail ) {
        $debug and print "$indent| +f=@{[_dump($f)]}\n";
        $result{$f->[0]} = $f;
    }
    print "${indent}node $depth out fail=@{[_dump_node(\%result)]}\n" if $debug;
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
        map  { $_->[0] }
        sort { $a->[1] cmp $b->[1] }
        map  { [$_, join( '|' =>
            scalar(grep {ref($_) eq 'HASH'} @{$node->{$_}}),
            _node_offset($node->{$_}),
            scalar @{$node->{$_}},
        )]}
    keys %$node ) {
        print "$indent| off=", _node_offset($node->{$n}),"\n"
            if $debug;
        my( $end, @path ) = reverse @{$node->{$n}};
        if( ref($end) ne 'HASH' ) {
            print "$indent| path=($end:@{[_dump(\@path)]})\n" if $debug;
            push @{$reduce{$end}}, [ $end, @path ];
        }
        else {
            my( $common, $tail ) = _reduce_node( $end, $debug, 1+$depth );
            if( not @$common ) {
                $debug and print "$indent| +failed $n\n";
                push @fail, [reverse(@path), $tail];
            }
            else {
                if( $debug ) {
                    print "$indent| ++recovered common=@{[_dump($common)]} tail=";
                    if( ref($tail) eq 'HASH' ) {
                        print 'n:', _dump_node($tail);
                    }
                    else {
                        print 'p:', _dump($tail);
                    }
                    print " path=@{[_dump(\@path)]}\n";
                }
                if( @path >= 1
                    and ref($tail) eq 'HASH'
                    and exists $tail->{''}
                    and keys %$tail == 2
                ) {
                    $debug and print "$indent: attempt slide\n";
                    ($common, $tail, @path) =
                        _slide_tail( $common, $tail, \@path, $debug, 1+$depth );
                    $debug and print "$indent| +slid common=@{[_dump($common)]} tail=@{[_dump_node($tail)]} path=@{[_dump(\@path)]}\n";
                }
                push @{$reduce{$common->[0]}}, [
                    @$common, 
                    (ref($tail) eq 'HASH' ? $tail : @$tail ),
                    @path
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
    print "$indent| do @{[_dump($path)]}\n" if $debug;
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
        $ra->insert( @$p );
    }
    $path = $ra->_path;
    $debug and print "$indent| path=@{[_dump($path)]}\n";
    my $common = [];
    push @$common, shift @$path while( ref($path->[0]) ne 'HASH' );
    my $tail = scalar( @$path ) > 1 ? [@$path] : $path->[0];
    $debug and print "$indent| common=@{[_dump($common)]} tail=@{[_dump([$tail])]}\n";
    ($common, $tail);
}

sub _node_offset {
    # return the offset that the first node is found, or -ve
    # my $path = shift;
    my $nr = @{$_[0]};
    for( my $atom = 0; $atom < $nr; ++$atom ) {
        return $atom if ref($_[0]->[$atom]) eq 'HASH';
    }
    return -1;
}

sub _slide_tail {
    my $head   = shift;
    my $tail   = shift;
    my $path   = shift;
    my $debug  = shift;
    my $depth  = shift;
    my $indent = ' ' x $depth;

    my $slide_node = $tail;
    print "$indent| try to slide", _dump_node($slide_node), "\n" if $debug;
    my $slide_path;
    my $s;
    # get the key that is not ''
    while( $s = each %$slide_node ) {
        if( $s ) {
            $slide_path = $slide_node->{$s};
            last;
        }
    }
    print "$indent| slide potential ", _dump($slide_path), " over ",
        _dump($path), "\n"
            if $debug;
    while( defined $path->[0] and $slide_path->[0] eq $path->[0] ) {
        print "$indent| slide=tail=$slide_path->[0]\n" if $debug;
        my $slide = shift @$path;
        shift @$slide_path;
        push @$slide_path, $slide;
        push @$head, $slide;
    }
    print "$indent| slide path ", _dump($slide_path), "\n" if $debug;
    my $key = do {
        if( ref($slide_path->[0]) eq 'HASH' ) {
            _node_key($slide_path->[0]);
        }
        else {
            $slide_path->[0];
        }
    };
    $slide_node = { '' => undef, $key => $slide_path };
    print "$indent| slide final ", _dump_node($slide_node), "\n"
        if $debug;
    ($head, $slide_node, @$path);
}

sub _unrev_path {
    my ($path, $debug, $depth) = @_;
    my $indent = ' ' x $depth;
    my $new;
    if( not grep { ref($_) } @$path ) {
        print "${indent}_unrev path fast ", _dump($path) if $debug;
        $new = [reverse @$path];
        print " -> ", _dump($new), "\n" if $debug;
        return $new;
    }
    print "${indent}unrev path in ", _dump($path), "\n" if $debug;
    while( defined( my $p = pop @$path )) {
        push @$new, ref($p) eq 'HASH'
            ? _unrev_node($p, $debug, 1+$depth)
            : $p
        ;
    }
    print "${indent}unrev path out ", _dump($new), "\n" if $debug;
    $new;
}

sub _unrev_node {
    my ($node, $debug, $depth) = @_;
    my $indent = ' ' x $depth;
    croak "was not passed a HASH ref\n", _dump([$node]), "\n" unless ref($node) eq 'HASH';
    my $optional = _remove_optional($node);
    print "${indent}unrev node in ", _dump_node($node), " opt=$optional\n" if $debug;
    my $new;
    $new->{''} = undef if $optional;
    my $n;
    for $n( keys %$node ) {
        my $path = _unrev_path($node->{$n}, $debug, 1+$depth);
        $new->{_node_key($path->[0])} = $path;
    }
    print "${indent}unrev node out ", _dump_node($new), "\n" if $debug;
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

sub _re_path {
    my $in  = shift;
    ref($in) ne 'ARRAY'
        and croak "was not passed an ARRAY ref\n", _dump([$in]), "\n";
    my $out = '';
    for my $p( @$in ) {
        if( ref($p) eq '' ) {
            $out .= $p;
        }
        else {
            my $path = [
                map { _re_path( $p->{$_} ) }
                grep { $_ ne '' }
                keys %$p
            ];
            my $nr     = @$path;
            my $nr_one = grep { length($_) == 1 } @$path;
            if( $nr_one == 1 and $nr == 1 ) {
                $out .= $path->[0];
            }
            elsif( $nr_one > 1 and $nr_one == $nr ) {
                $out .= _make_class(@$path);
            }
            else {
                if( $nr_one < 2 ) {
                    $out .= '(?:'
                        . join( '|' => sort _re_sort @$path )
                        . ')'
                    ;
                }
                else {
                    $out .= '(?:'
                        . do {
                            my( @short, @long );
                            push @{length $_ > 1 ? \@long : @short}, $_ for @$path;
                            join( '|', ( sort( _re_sort @long ), _make_class(@short) ))
                        }
                        . ')'
                    ;
                }
            }
            $out .= '?' if exists $p->{''};
        }
    }
    $out;
}

sub _re_path_pretty {
    my $in  = shift;
    my $arg = shift;
    if( ref($in) ne 'ARRAY' ) {
        croak "was not passed an ARRAY ref\n", _dump([$in]), "\n";
    }
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
        else {
            my $path = [
                map { _re_path_pretty( $in->[$p]{$_}, $arg ) }
                grep { $_ ne '' }
                keys %{$in->[$p]}
            ];
            my $nr     = @$path;
            my $nr_one = grep { length($_) == 1 } @$path;
            if( $nr_one == $nr ) {
                $out .= "\n$pre" if $prev_was_paren;
                $out .=  $nr == 1 ? $path->[0] : _make_class(@$path);

                $out .= '?' if exists $in->[$p]{''};
                $prev_was_paren = 0;
            }
            else {
                $out .= "\n" if length $out;
                $out .= $pre if $p or $prev_was_paren;
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
                            push @{length $_ > 1 ? \@long : @short}, $_ for @$path;
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

sub _make_class {
    my $class = join( '' => sort @_ );
    if( $class eq '0123456789' ) {
        '\\d';
    }
    else {
        $class =~ s/0123456789/\\d/;
        "[$class]";
    }
}

sub _re_sort {
    length $b <=> length $a || $a cmp $b
}

sub _node_eq {
    if( not defined $_[0] or not defined $_[1] ) {
        0;
    }
    elsif( ref($_[0]) eq 'HASH' and ref($_[1]) eq 'HASH' ) {
        keys %{$_[0]} == keys %{$_[1]}
            and
        join( '|' => keys %{$_[0]}) eq join( '|' => keys %{$_[1]})
            and
        _re_path( [$_[0]] ) eq _re_path( [$_[1]] );
    }
    elsif( ref($_[0]) eq 'ARRAY' and ref($_[1]) eq 'ARRAY' ) {
        _re_path($_[0]) eq _re_path($_[1]);
    }
    elsif( ref($_[0]) eq '' and ref($_[1]) eq '' ) {
        $_[0] eq $_[1];
    }
    else {
        0;
    }
}

sub _dump {
    my $path = shift;
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
            if( $d =~ /\s/ or not length $d ) {
                $dump .= qq{'$d'};
            }
            else {
                $dump .= $d;
            }
        }
        else {
            $dump .= '*';
        }
    }
    $dump .= ']';
    $dump;
}

sub _dump_node {
    my $node = shift;
    my $dump = '{';
    my $nr   = 0;
    my $n;
    for $n (sort keys %$node) {
        $dump .= ' ' if $nr++;
        if( $n eq '' and not defined $node->{$n}  ) {
            $dump .= '*';
        }
        else {
            $dump .= "$n=>" . _dump($node->{$n});
        }
    }
    $dump .= '}';
    $dump;
}

1;

__END__

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

"lexed a zero-length token, an infinite loop would ensue"

The C<add> method eats the input string one token at a time. If you
supply your own lexer pattern, it may match the null character, in
which case the loop that processes the string will loop an infinite
number of times. Solution: Fix your pattern.

"was not passed an ARRAY ref"

A coding error. Can only occur when debugging is active. Solution:
turn off debugging (it's off by default).

"was not passed a HASH ref"

A coding error. Can only occur when debugging is active. Solution:
turn off debugging (it's off by default).

=head1 NOTES

This module has been tested successfully with a range of versions
of perl, from 5.005_03 to 5.8.6.

The expressions produced by this module can be used with the PCRE
library.

Where possible, feed R::A the simplest tokens possible. Don't add
C<a(?-\d+){2})b> when C<a-\d+-\d+b>. The reason is that if you
also add C<a\d+c> the resulting REs change dramatically:
C<a(?:(?:-\d+){2}b|-\d+c)> I<versus> C<a-\d+(?:-\d+b|c)>.  Since
R::A doesn't analyse tokens, it doesn't know how to "unroll" the
C<{2}> quantifier, and will fail to notice the divergence after the
first C<-d\d+>.

What is more, when the string 'a-123000z' is matched against the
first pattern, the regexp engine will have to backtrack over each
alternation before determining that there is no match. No such
backtracking occurs in the second pattern: The engine scans up to
the 'z' and then fails immediately, since neither of the alternations
start with 'z'.

R::A does, however, understand character classes. Given C<a-b>,
C<axb> and C<a\db>, it will assemble these into C<a[-\dx]b>. When
- appears as a candidate for a character class it will be the first
character in the class.  When ^ appears as a candidate for a character
class it will be the last character in the class. R::A will also
replace all the digits 0..9 appearing in a character class by C<\d>.
I'd do it for letters as well, but thinking about accented characters
and other glyphs hurts my head.

=head1 SEE ALSO

=over 4

=item Regex::PreSuf

C<Regex::PreSuf> takes a string and chops it itself into tokens of
length 1. Since it can't deal with tokens of more than one character,
it can't deal with meta-characters and thus no regular expressions.
Which is the main reason why I wrote this module.

=item Regexp::Optimizer

C<Regexp::Optimizer> produces regular expressions that are similar to
those produced by R::A with reductions switched off.

=item Text::Trie

C<Text::Trie> is well worth investigating. Tries can outperform very
bushy (read: many alternations) patterns.

=back

=head1 LIMITATIONS

The current version does not let you know which initial regular
expression, that forms part of the assembled RE, was the one that
caused the match.  This may be addressed in a future version. (The
solution probably lies in using the C<(?{code})> contruct to assist
in tagging the original expressions).

C<Regexp::Assemble> does not attempt to find common substrings. For
instance, it will not collapse C</aabababc/> down to C</a(?:ab}{3}c/>.
If there's a module out there that performs this sort of string
analysis I'd like to know about it. But keep in mind that the
algorithms that do this are very expensive: quadratic or worse.

C<Regexp::Assemble> does not emit lookahead or lookbehind assertions
in the expressions it produces. Nor is the wonderful and frightening
C<(?>...)> construct used. These and other optimisations may be
introduced in further releases if there is a demand for them, if I
figure out how to use them in this module, or if someone sends
patches.

You can't remove a pattern that has been added to an object. You'll
just have to start over again. Adding a pattern is difficult enough,
I'd need a solid argument to convince me to add a C<remove> method.
If you need to do this you should read the documentation on the
C<mutable> and C<clone> methods.

=head1 BUGS

The module does not produce POSIX-style regular expressions.

The algorithm used to assemble the regular expressions makes extensive
use of mutually-recursive functions (I<i.e.>: A calls B, B calls A,
...) For deeply similar expressions, it may be possible to provoke
"Deep recursion" warnings.

C<Regexp::Assemble> does not assign meaning to meta-characters.
For instance, if the following two pattern lists are given: C<a\d>
and C<a\d+>, it will not determine that C<\d> can be matched by
C<\d+>. Instead, it will produce C<a(?:\d|\d+)>. Along a similar
line of reasoning, it will not determine that C<a> and C<a\d+> is
equivalent to C<a\d*> (It will produce C<a(?:\d+)?> instead).

When a string is tested against an assembled RE, it may match when
it shouldn't, or else not match when it should. The module has been
tested extensively, and has an extensive test suite, but you never
know... In either case, it is a bug, and I want to know about it.

A temporary work-around is to disable reductions:

  my $pattern = $assembler->reduce(0)->re;

A discussion about implementation details and where I think bugs
might lie appears in the accompanying README file. If this file is
not available locally, you should be able to find a copy on the Web
at your nearest CPAN mirror.

Please report all bugs at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Regexp-Assemble|rt.cpan.org>

Make sure you include the output from the following two commands:

  perl -MRegexp::Assemble -le 'print Regexp::Assemble::VERSION'
  perl -V

If you are feeling brave, extensive debugging traces are available.

Note that perl 5.6.0 has a bug that re-escapes backslashes that
occur in qw// quoted word lists. You will come to grief if you try
to build patterns statically in this way, should they contain
metacharacters like C<\d>. If you read patterns in from a file you
should have no problems. The real solution is to upgrade to at least
5.6.1, if not 5.6.2 or more recent. Or downgrade. Anything but
5.6.0.

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

Thanks go to Jean Forget and Philippe Blayo who looked over
an early version, H. Merijn Brandt, who stopped over in Paris one
evening, and discussed things over a few beers. Nicholas Clark
pointed out that while what this module does (?:c|sh)ould be done
in perl's core, as per the 2004 TODO, he encouraged to me continue
with the development of this module. In any event, this module
allows one to gauge the difficulty of undertaking the endeavour in
C. I'd rather gouge my eyes out with a blunt pencil.

A tip 'o the hat to Paul Johnson who settled the question as to
whether this module should live in the Regex:: namespace, or
Regexp:: namespace.  If you're not convinced, try running the
following one-liner:

  perl -le 'print ref qr//'

Thanks also to broquaint on Perlmonks, who answered a question
pertaining to traversing an early version of the underlying data
structure used by the module (Sadly, that code is no more). bart
and ysth also provided a couple of tips pertaining to the Correct
Use of overloading.

=head1 AUTHOR

David Landgren, david@landgren.net

Copyright (C) 2004

http://www.landgren.net/perl/

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

1;
__END__
