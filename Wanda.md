Wanda
=====

Wanda is a Forth-like language.  Despite being Forth-like, however, it is
arguably inappropriate to call it "concatenative", or even "stack-based",
because it is based on a string-rewriting semantics.

The remainder of this document will describe the language and will attempt
to justify the above statement.

Basics
------

    -> Functionality "Run Wanda program" is implemented by
    -> shell command "lua src/wanda.lua %(test-body-file)"

    -> Tests for functionality "Run Wanda program"

A Wanda expression is a string of symbols.  Each symbol consist of one or more
non-whitespace characters.  In the string, symbols are separated by whitespace.

Here is a legal Wanda expression.  (The `===>` is not part of the expression;
it shows the expected result of running the program.)

    2 3 + 4 *
    ===> 20

Evaluation happens by successively rewriting parts of this string of symbols.
For example, in the above, `2 3 +` is rewritten into `5`, then `5 4 *` is
rewritten into `20`.

Rewrites occur when parts of the string match the pattern of one of the
rewrite rules that are in effect.  For instance, the rule for `+` has the
pattern `X Y +`, where X and Y are integers; the part of the string that
matches that pattern is replaced by a single integer which is the sum of
X and Y.

If no patterns match anywhere in the string, the expression remains unchanged
and evaluation terminates.

    2 +
    ===> 2 +

So, we see that, despite looking like and evaluating like a Forth program,
there is no stack separate from the program.  It's all just a string which
gets rewritten.  "2" is not a value of the stack, nor an instruction that
pushes the value 2 onto the stack; it's just a "2".

### Some other builtins

We've seen `+` and `*`, which are built-in rules.
There are a couple of other built-in rules.

    7 3 -
    ===> 4

    4 dup
    ===> 4 4

    4 5 swap
    ===> 5 4

Defining functions
------------------

Wanda supports a special form for defining functions, which is very similar to
Forth's `:` ... `;` block.  The main difference is that there is a `->` symbol
inside it, which you can think of as a way to making it explicit where the
function naming ends and the function definition begins.

    : perim -> + 2 * ;
    4 10 perim
    ===> 28

You can in fact think of this special form as something that gets rewritten
into nothingness (a zero-length string) and which introduces a new rule as a
side effect.  The new rule matches the function naming (in this case `perim`)
and replaces it with its definition (in this case `+ 2 *`), like so:

    4 10 + 2 *

(And then evaluation continues as usual to obtain the final result.)

Note that these rules are applied in the order in which they are defined,
that is to say, source-code order:

    : ten -> 10 ;
    : ten -> 11 ;
    ten
    ===> 11


Recursion
---------

If we include the name of a function in its definition, recursion ought to
happen.  For example if we said

    : fact -> dup 1 - fact * ;

then

    4 fact

would rewrite to

    4 dup 1 - fact *

which is fine, the next `fact` will get rewritten the same way in due course,
all fine except for the fact that it will never terminate because we haven't
given a base case.

What would be great would be some way for `0 fact` to be immediately rewritten
into `1` instead of recursing.

Well, this is what the extra `->` is for in a `:` ... `;` block — so that we
can specify both the pattern and the replacement.  So, if we say

    : 0 fact -> 1 ;

we have defined a rule which matches `0 fact` and replaces it with `1`.

    : 0 fact -> 1 ;
    : fact -> dup 1 - fact * ;
    5 fact
    ===> 120

On the surface it may seem like the order of rule application matters in
the above, but in fact it does not:

    : fact -> dup 1 - fact * ;
    : 0 fact -> 1 ;
    5 fact
    ===> 120

This is because the string is searched left-to-right for the first match,
and if the string contains `0 fact`, this will always match `0 fact` before
we're even in a position to check the parts of the string to the right of
the `0` for the pattern `fact`.

Computational class
-------------------

If we stop here, what kinds of things can Wanda compute?

And, in fact, let's stop here for now and call what we have to far
**Core Wanda**, and ask: what kinds of things can Core Wanda compute?

We've already seen it can compute factorial, which means
it's moderately powerful — but that by itself doesn't mean it's
Turing-complete.

It's well-known that with a strict stack discipline, you only have
a push-down automaton, not a Turing machine.  However, we don't have
that, in two ways.  One, `swap` violates the strict stack discipline,
as it allows the program to access the top two elements of the stack
arbitrarily.  Two, we haven't said if the stack elements come from
a finite set or not — if they're unbounded integers, you can use
that fact, plus `swap`, to build a [2-register machine][].

So let's say integers on the stack are bounded (say, 32-bit signed integers
by default), to exclude that possibility.

But all the above in fact assumes this is a traditional stack-based language,
which it's not!  It's a string-rewriting language, and it naturally has
access to the deep parts of the stack, because it looks for patterns in them.

In fact it ought to work basically as [Thue][] does.  The order in which
rules are applied is known instead of being unspecified (nondeterministic),
but that's not an impediment from the perspective of seeing what it can
compute — a program which is written to accomodate an unspecified rewriting
order will also work when the order is specified and fixed, as it is here.

So Wanda is Turing-complete if Thue is, and Thue is.

[2-register machine]: https://esolangs.org/wiki/Minsky_machine
[Thue]: https://esolangs.org/wiki/Thue

History
-------

Wanda was originally conceived in 2009.  I distinctly remember working on
its reference implementation (in Haskell) on a laptop in a laundromat in
Seattle.  For some reason it had a right-to-left rewriting order.
I'm not exactly certain why I shelved it.  I think certain things about it
were somewhat mystifying to me (I don't recall why I thought it benefited
from having a right-to-left rewriting order) and/or it seemed like
already-explored territory (again, I don't have a clear example of why I
might have thought that; I might have encountered [Enchilda][] at that
point; however, I think that was later — I don't think I had even heard of
"concatenative" at that time — and besides, Enchilada is not all that
similar.)

[Enchilada]: http://www.enchiladacode.nl/

Further Work
------------

If what's described here is Core Wanda, that suggests there might be
more that could be productively added, and I do believe that.

One thing that is atrractive is the possibility for creating new
rules that are not written statically in the initial program.  And
possibly retracting existing rules too, but this seems less exciting.
But I haven't worked out a way to do this yet that I like.

Appendix A.  Direct Comparison with Stack-Based and Concatenative Languages
---------------------------------------------------------------------------

Consider the expression:

    2 3 + 4 *

In a "stack language" like Forth, this would be interpreted as

    push 2
    push 3
    pop off top two stack elements, add them, push result on stack
    push 4
    pop off top two stack elements, multiply them, push result on stack

In a "concatenative" language, it would be interpreted (using a
Javascript-like language solely to illustrate it explicitly) as

    function(stack) {
        return mul(push(4, add(push(3, push(2, stack)))));
    }

In both of these, the result of running it on an empty stack would
be a stack containing one element, the integer 20.

That would also, roughly speaking, be the result of running it in
Wanda.  However, it would be arrived at as follows.

    the builtin rule "X Y + => [X+Y]" matches the substring
        "2 3 +" and generates the replacement string "5"
    "2 3 +" is replaced by "5" in the expression, leaving "5 4 *"
    the builtin rule "X Y * => [X*Y]" matches the substring
        "5 4 *" and generates the replacement string "20"
    "5 4 *" is replaced by "20" in the expression, leaving "20"
    no other rules match, yielding "20" as the final result

Appendix B.  Pseudo-code for interpretation
-------------------------------------------

    rules = (initialized with built-in rules)
    split program string by spaces into an array called "redex"
    start-index = 0
    while start-index < len(redex):
        rest-of-redex = redex[start-index ... end]
        match-info = find first rule in rules that matches rest-of-redex
        if match-info is None:
            start-index += 1
            continue
        redex = match-info.rule.replace(redex)
        start-index = 0
     return redex

For this, we need a definition of `match` and we need each rule to define a
method `replace`.  For user-defined rules, this has a simple subtitution
action, but built-in rules such as `; foo -> bar ;` have side effects such as
updating `rules`.
