# sexpr-plus [![npm package](https://img.shields.io/npm/v/sexpr-plus.svg?style=flat-square)][1] [![CI status](https://img.shields.io/travis/anko/sexpr-plus.svg?style=flat-square)][2]

Recursive descent parser for S-expressions, with features useful for writing an
S-expr-based programming language.  Written for [eslisp][3], but generalisable.

Outputs an array containing objects representing parsed forms:

-   Lists are parsed to `{ type: "list", content: [ <other objects>... ] }`.
-   Atoms are parsed to `{ type: "atom", content: "<atomName>" }`.
-   Strings (delimited with `"`s) are parsed to `{ type: "string", content:
    "<atomName>" }`.  They support all the escape sequences ECMAScript 6 strings
    can take, including `\"`, `\\`, `\n`, `\r`, `\t`, `\f`, `\b`, `\0`, ASCII
    escapes like `\x3c`, and Unicode escapes like `\uD801` or `\u{1D306}`. The
    hex digits for `\xNN`, `\uNNNN`, and `\u{N}` are case-insensitive.
    Any other escaped character just returns itself.
-   Atoms can also have characters within them escaped, and have all the same
    escape sequences as strings.
-   Supports quote, quasiquote, unquote and unquote-splicing, with `'`, `` `
    ``, `,` and `,@`.  They're turned into the appropriate atoms.
-   Comments are from `;` til end of line.  They are not present in the output.

Inputs containing only comments and/or whitespace produce an empty array.

Initially forked from the more minimal [fwg/s-expression][4], but then rewritten
in PEG.js and again in LiveScript.

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
var sexpr = require("sexpr-plus")
```

Call `sexpr.parse` with a string containing code to parse. If the string fails
to parse, a `sexpr.SyntaxError` (an `Error` subclass) is thrown with the
following properties:

-   `expected` - The expected token, if applicable.
-   `found` - The found token.
-   `location` - The location the error occurred, in the above format (`offset`,
    `line`, and `column`).
-   `message` - The error message.
-   `name` - `"SyntaxError"`

If `Error.captureStackTrace` is available (like in Node), that is used to add a
stack trace to a `stack` property on the instance.

## License

[MIT][5].

[1]: https://www.npmjs.com/package/sexpr-plus
[2]: https://travis-ci.org/anko/sexpr-plus
[3]: https://github.com/anko/eslisp
[4]: https://github.com/fwg/s-expression
[5]: LICENSE
