Wanda
=====

Wanda is a Forth-like language with string-rewriting semantics,
meaning it is arguably not fair to call it "concatenative",
or even "stack-based".  (For a more detailed explanation of what
these things mean, see the Tutorial section.)

Basics
------

    -> Functionality "Run Wanda program" is implemented by
    -> shell command "lua src/wanda.lua %(test-body-file)"

    -> Tests for functionality "Run Wanda program"

A Wanda expression is a string of symbols.
Each symbol may consist of several characters.
In the string, symbols are separated by whitespace.
Here is a legal Wanda expression.  (The `===>` is
not part of the Wanda program; it shows the expected
result of running the program.)

    2 3 + 4 *
    ===> 20

Evaluation happens by successively rewriting parts
of the string of symbols.  For example, in the above,
`2 3 +` is rewritten into `5`, then `5 4 *` is
rewritten into 20.

Rewrites occur when parts of the string match the
pattern of one of the rules in effect.  For instance,
the rule for `+` has the pattern `X Y +` where X and Y
must be integers.

If no patterns match, the expression remains unchanged
and evaluation terminates.

    2 +
    ===> 2 +

### Some other builtins

We've seen `+` and `*`, which are built-in rules.
There are a couple of other built-in rules.

    7 3 -
    ===> 4

    4 dup
    ===> 4 4

    4 5 swap
    ===> 5 4

Also note that all the numbers are 64-bit signed ints.
(This will become relevant later on.)

Defining functions
------------------

Wanda supports a special form for defining functions,
which is very similar to Forth's `:` ... `;` block.
The main difference is that there is a `->` operator
inside it, which you can think of as a way to making
it explicit where the function naming ends and the
definition begins.

    : perim -> + 2 * ;
    4 10 perim
    ===> 28

You can in fact think of this special form as something
that gets rewritten into nothingness and which
introduces a new rule as a side effect.  The new rule
matches the function naming (in this case `perim`) and
replaces it by its definition (in this case `+ 2 *`),
like so:

    4 10 + 2 *

(And then evaluation continues as usual, to get the
final result.)

Recursion
---------

If we include the name of a function in its definition,
recursion ought to happen.  For example if we said

    : fact -> dup 1 - fact * ;

then

    4 fact

would rewrite to

    4 dup 1 - fact *

which is fine, the next `fact` will get rewritten the
same way in due course, all fine except for the fact that it
will never terminate.

What would be great is some way for `0 fact` to be rewritten
into `1` without any recursion.

Well, this is what the extra `->` is for in a definition --
so that we can tell what is the pattern and what is the
replacement.  If we say

    : 0 fact -> 1 ;

we have defined a rule which matches `0 fact` and replaces
it with `1`.  Rules are matched in source-code order.  So,
with this, we can then say

    : 0 fact -> 1 ;
    : fact -> dup 1 - fact * ;
    5 fact
    ===> 120

Pseudo-code for interpretation
------------------------------

    rules = (initialized with built-in rules)
    split program string by spaces into an array called "redex"
    start-index = 0
    while start-index < len(redex):
        match-info = find first rule in rules that matches redex[start-index ... end]
        if match-info is None:
            start-index += 1
            continue
        redex = match-info.rule.replace(redex)
        start-index = 0
     return redex

For this, we need a definition of "match" and we need each rule to define a method
"replace".  For user-defined rules, this has a simple subtitution action, but
built-in rules such as `[ foo -> bar ]` have side effects such as updating `rules`.

Computational class
-------------------

If we stop here, what kinds of things can Wanda compute?
We've already seen it can compute factorial, which means
it's moderately powerful - but it doesn't mean it's
Turing-complete.

...

History
-------

Wanda was originally conceived in 2009.  I distinctly remember
working on its reference implementation on a laptop in a laundromat in Seattle.
For some reason it had a right-to-left rewriting order.
Certain things about it mystified me and I think that's why I shelved it.
But looking at that work now, what mystifies me the most was why I thought
it needed a right-to-left rewriting order.

Tutorial section
----------------

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


