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
    -> shell command "python src/wanda.py %(test-body-file)"

    -> Tests for functionality "Run Wanda program"

A Wanda expression is a string of symbols.  Each symbol consist of one or more
non-whitespace characters.  In the string, symbols are separated by whitespace.

Here is a legal Wanda expression.  (The `===>` is not part of the expression;
it shows the expected result of running the program.)

    $ 2 3 + 4 *
    ===> 20 $

Evaluation happens by successively rewriting parts of this string of symbols.
For example, in the above,

*   `$ 2` is rewritten into `2 $`
*   `$ 3` is rewritten into `3 $`
*   `2 3 $ +` is rewritten into `5 $`
*   `$ 4` is rewritten into `4 $`
*   finally, `5 4 $ *` is rewritten into `20 $`.

Rewrites occur when parts of the string match the pattern of one of the
rewrite rules that are in effect.  For instance, the rule for `+` has the
pattern `X Y $ +`, where X and Y are integers; the part of the string that
matches that pattern is replaced by a single integer which is the sum of
X and Y, followed by a `$`.

If no patterns match anywhere in the string, the expression remains unchanged
and evaluation terminates.

    2 $ +
    ===> 2 $ +

You can think of `$` as a symbol which delineates the stack (on the left)
from the program (on the right).  When constants are encountered in the
program, they are pushed onto the stack.

But if you do think of it this way, keep in mind that it is only a
convenient illusion.  For despite mostly looking like and evaluating like a
Forth program, there is no "stack" that is distinct from the program — it's
all just a string that gets rewritten.  `2` is neither an element on the
stack, nor an instruction that pushes the value 2 onto the stack; it's just
a `2`.

### Some other builtins

We've seen `+` and `*`, which are built-in rules.
There are a couple of other built-in rules.

    $ 7 sgn 0 sgn -14 sgn
    ===> 1 0 -1 $

    5 4 $ pop
    ===> 5 $

    4 $ dup
    ===> 4 4 $

Defining functions
------------------

Wanda supports a special form for defining functions, which is very similar to
Forth's `:` ... `;` block.  The main difference is that there is a `->` symbol
inside it, which you can think of as a way to making it explicit where the
function naming ends and the function definition begins.

    : $ perim -> $ + 2 * ;
    4 10 $ perim
    ===> 28 $

You can in fact think of this special form as something that gets rewritten
into nothingness (a zero-length string) and which introduces a new rule as a
side effect.  The new rule matches the function naming (in this case `perim`)
and replaces it with its definition (in this case `+ 2 *`), like so:

    4 10 $ + 2 *

(And then evaluation continues as usual to obtain the final result.)

Note that these rules are applied in the order in which they are defined,
that is to say, source-code order:

    : $ ten -> $ 10 ;
    : $ ten -> $ 11 ;
    $ ten
    ===> 11 $

Note there is another restriction: exactly one `$` symbol must occur to
the left of the `->`, and exactly one `$` symbol must occur to the right
of the `->` as well.  Often the `$` will simply be in the leftmost
position in both of these occurrences, as in the example above, but this
is not required.

Recursion
---------

If we include the name of a function in its definition, recursion ought to
happen.  For example if we said

    : $ fact -> $ dup 1 - fact * ;

then

    4 $ fact

would rewrite to

    4 $ dup 1 - fact *

which is fine, the next `fact` will get rewritten the same way in due course,
all fine except for the troublesome matter of it never terminating because we
haven't given a base case.

What would be great would be some way for `0 fact` to be immediately rewritten
into `1` instead of recursing.

Well, this is what the extra `->` is for in a `:` ... `;` block — so that we
can specify both the pattern and the replacement.  So, if we say

    : 0 $ fact -> $ 1 ;

we have defined a rule which matches `0 $ fact` and replaces it with `$ 1`
(which will immediatey rewrite to `1 $`).  Thus the recursion can terminate:

    : 0 $ fact -> $ 1 ;
    : $ fact -> $ dup 1 - fact * ;
    $ 5 fact
    ===> 120 $

At first blush it may seem like the order of rule application matters in
the above, but in fact it does not:

    : $ fact -> $ dup 1 - fact * ;
    : 0 $ fact -> $ 1 ;
    $ 5 fact
    ===> 120 $

This is because the string is searched left-to-right for the first match,
and if the string contains `0 fact`, this will always match `0 fact` before
we're even in a position to check the parts of the string to the right of
the `0` for the pattern `fact`.

Computational class
-------------------

We can ask ourselves: if we stop here (and perhaps call what we've got so
far **Core Wanda**), what kinds of things can we compute with it?

Well, we have a stack discipline, and it's well-known that if you have
a strict stack discipline you have a push-down automaton, not a Turing
machine.

But that assumes this is a traditional stack-based language,
which it's not!  It's a string-rewriting language, and it naturally has
access to the deep parts of the stack, because it looks for patterns in them.

In fact, from this viewpoint, the language looks a lot like a deterministic
version of [Thue][].  And Thue is Turing-complete, and the additional
determinism isn't an impediment from the perspective of seeing what it can
compute (a program which is written to accomodate an unspecified rewriting
order can be written to work the same when the order is specified and fixed).

However, there's an intentional twist: every rewrite rule must contain
exactly one `$` on the left and exactly one `$` on the right.

If the redex (the string currently being rewritten) likewise contains
exactly one `$`, I _think_ (but have not proved) that this limits the kinds
of rewrites that can be undertaken in exactly the same way a strict
stack discipline does, i.e. it can only compute what a push-down automaton
can compute.

However,

*   as I said, I haven't proved this, and it relies on the fact that
    user-defined rules can't have patterns with variables and that we
    can't simulate variables over a finite set of possible elements
    they can match by introducing one rule for every element of that
    finite set.
*   we haven't restricted the redex to containing exactly one `$` and I
    haven't thought through what the implications of having more than one
    `$` in it are anyway.

So the approach we'll take in the remainder of this document is to
add some features and show that they make the language Turing-complete,
even if Core Wanda already is.

[2-register machine]: https://esolangs.org/wiki/Minsky_machine
[Thue]: https://esolangs.org/wiki/Thue

Concrete Shoes and Fishing Lines
--------------------------------

Let's introduce some built-in rules that allow us to manipulate values
at the left end of the string, i.e. deep in the "stack".  This should
allow us to construct a Tag system, and be Turing-complete that way,
if we like.

In fact, since we're imagining part of this string is a "stack" anyway,
we might as well go further and imagine it's a body of water.

To store a value on the left end of the string, what we'll do is
"tie a weight" to it and let it "sink" to the bottom.  When we need it
again, we'll "fish it out".

    # 1 2 3 4 5 $ 99 sink
    # ===> 99 1 2 3 4 5 $

It might be illustrative to watch the trace of this.  It should be
something like:

    1 2 3 4 5 $ 99 sink
    1 2 3 4 $ 99 sinking 5
    1 2 3 $ 99 sinking 4 5
    1 2 $ 99 sinking 3 4 5
    1 $ 99 sinking 2 3 4 5
    $ 99 sinking 1 2 3 4 5
    99 $ bubble 1 2 3 4 5
    99 1 $ bubble 2 3 4 5
    99 1 2 $ bubble 3 4 5
    99 1 2 3 $ bubble 4 5
    99 1 2 3 4 $ bubble 5
    99 1 2 3 4 5 $ bubble
    99 1 2 3 4 5 $

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

The analagous expression in Wanda would be

    $ 2 3 + 4 *

And the result would be analogous to the "stack language" and
"concatenative" results

    20 $

It would be arrived at as follows.

    TODO spell it out here

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
action, but built-in rules such as `: ... ;` have side effects such as
updating `rules`.
