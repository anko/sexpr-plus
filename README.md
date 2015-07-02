# S-expression+ [![CI status](https://img.shields.io/travis/anko/sexpr-plus.svg?style=flat-square)][1]

Recursive descent parser for S-expressions, with features useful for writing an
S-expr-based programming language.  Written for [eslisp][2], but generalisable.

-   Lists are parsed to arrays.
-   Atoms are parsed as strings.
-   String literals delimited by `"` are parsed into `String` objects to make
    them distinct from the other atoms. Escape sequences `\"`, `\\`, `\n`,
    `\r`, `\t`, `\f`, and `\b` are supported.
-   Supports quote, quasiquote, unquote and unquote-splicing, with `'`, `` `
    ``, `,` and `,@`.
-   Supports comments, from `;` til end of line.

Forked from the more minimal [fwg/s-expression][3].

### Usage

<!-- !test program
awk '{ print "console.dir(" $0 ");" }' \
| sed '1s:^:var p = require("./index.js").parse;:' \
| node \
| head -c -1
-->

`var p = require("sexpr-plus").parse;`, then

<!-- !test in 1 -->

    p('')
    p('a')
    p('a ; comment')
    p("()")
    p("(a b c)")
    p("'a")
    p("`(a ,b ,@c)")

<!-- !test out 1 -->

    null
    'a'
    'a'
    []
    [ 'a', 'b', 'c' ]
    [ 'quote', 'a' ]
    [ 'quasiquote',
      [ 'a', [ 'unquote', 'b' ], [ 'unquote-splicing', 'c' ] ] ]

#### License

[MIT][4].

[1]: https://travis-ci.org/anko/sexpr-plus
[2]: https://github.com/anko/eslisp
[3]: https://github.com/fwg/s-expression
[4]: LICENSE
