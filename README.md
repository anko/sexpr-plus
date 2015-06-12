# S-expression +

Recursive descent parser for S-expressions, with features useful for writing an
S-expr-based programming language.  Written for [eslisp][1], but generalisable.

-   Lists are parsed to arrays.
-   Atoms are parsed as strings.
-   String literals delimited by `"` are parsed into `String` objects to make
    them distinct from the other atoms. Escape sequences `\"`, `\\`, `\n`,
    `\r`, `\t`, `\f`, and `\b` are supported.
-   Supports quote, quasiquote, unquote and unquote-splicing, with `'`, `` `
    ``, `,` and `,@`.
-   Supports comments, from `;` til end of line.
-   Supports regular expression literals, in JavaScript's `/abcd/g` form.

Forked from the more minimal [fwg/s-expression][2].

### Examples

    var Parse = require('s-expr-plus');

    console.log(Parse('a')); // 'a'
    console.log(Parse('a ; comment')); // 'a'
    console.log(Parse("'a")); // ['quote', 'a']
    console.log(Parse('()')); // []
    console.log(Parse('(a b c)')); // ['a', 'b', 'c']
    console.log(Parse("(a 'b 'c)")); // ['a', ['quote' 'b'], ['quote', 'c']]
    console.log(Parse("(a '(b c))")); // ['a', ['quote', ['b', 'c']]]
    console.log(Parse("(a `(b ,c))")); // ['a', ['quasiquote', ['b', ['unquote', 'c']]]]
    console.log(Parse("(a `(b ,@c))")); // ['a', ['quasiquote', ['b', ['unquote-splicing', 'c']]]]

#### License

[MIT][3].

[1]: https://github.com/anko/eslisp
[2]: https://github.com/fwg/s-expression
[3]: LICENSE
