# sexpr-plus [![npm package](https://img.shields.io/npm/v/sexpr-plus.svg?style=flat-square)][1] [![CI status](https://img.shields.io/travis/anko/sexpr-plus.svg?style=flat-square)][2]

Recursive descent parser for S-expressions, with features useful for writing an
S-expr-based programming language.  Written for [eslisp][3], but generalisable.

Outputs an array containing objects representing parsed forms:

-   Lists are parsed to `{ type: "list", content: [ <other objects>... ] }`.
-   Atoms are parsed to `{ type: "atom", content: "<atomName>" }`.
-   Strings (delimited with `"`s) are parsed to `{ type: "string", content:
    "<atomName>" }`.  They support the same escape sequences as JavaScript
    strings: `\"`, `\\`, `\n`, `\r`, `\t`, `\f`, and `\b`.
-   Supports quote, quasiquote, unquote and unquote-splicing, with `'`, `` `
    ``, `,` and `,@`.  They're turned into the appropriate atoms.
-   Comments are from `;` til end of line.  They are not present in the output.

Empty inputs or inputs containing only comments produce an empty array.

Forked from the more minimal [fwg/s-expression][4].

## Node locations

All output nodes also have a `location` property, showing where in the input
that node originated:

    {
        start : { offset, line, column },
        end : { offset, line, column }
    }

All are integers: `offset` is the number of characters since the input, `line`
and `column` are 1-based and self-explanatory.

These may be handy for constructing source maps or showing more detailed error
messages.

## Usage

    npm i sexpr-plus

```js
var parse = require("sexpr-plus").parse;
```

Call `parse` with a string containing code to parse.

If you need to catch and distinguish between different types of `Error` with
`instanceof` while parsing, the syntax error prototype is available at
`require("sexpr-plus").SyntaxError`.

## License

[MIT][5].

[1]: https://www.npmjs.com/package/sexpr-plus
[2]: https://travis-ci.org/anko/sexpr-plus
[3]: https://github.com/anko/eslisp
[4]: https://github.com/fwg/s-expression
[5]: LICENSE
