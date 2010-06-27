Rasta
=====

Rasta is a parser and AST builder. It allows grammars to be programmed using a
DSL inside ruby and annotated to produce clean ASTs. Grammars are created
by composing native ruby objects, meaning they are fully dynamic and can
be even be built interactively.

Under the Hood
--------------

Rasta uses grammar combinators (implemented as messages to objects) to produce
a top-down back-tracking recursive descent parser.

To prevent possible exponential running times, Rasta uses adaptive
memoization.