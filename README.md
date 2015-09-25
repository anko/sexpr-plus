# S-expression+ [![CI status](https://img.shields.io/travis/anko/sexpr-plus.svg?style=flat-square)][1]

Recursive descent parser for S-expressions, with features useful for writing an
S-expr-based programming language.  Written for [eslisp][2], but generalisable.

Outputs an object, or null for empty input.

-   Lists are parsed to `{ type: "list", content: [ ... ] }`.
-   Atoms are parsed to `{ type: "atom", content: "<atomName>" }`.
-   Strings (delimited with `"`s) are parsed to `{ type: "string", content:
    "<atomName>" }`.  They support the same escape sequences as JavaScript
    strings: `\"`, `\\`, `\n`, `\r`, `\t`, `\f`, and `\b`.
-   Supports quote, quasiquote, unquote and unquote-splicing, with `'`, `` `
    ``, `,` and `,@`.  They're turned into the appropriate atoms.
-   Comments are from `;` til end of line.  They are not present in output.

Forked from the more minimal [fwg/s-expression][3].

### Usage

<!-- !test program
awk '{ print "console.log(JSON.stringify(" $0 ", null, 2));" }' \
| sed '1s:^:var p = require("./index.js").parse;:' \
| node \
| head -c -1
-->

`var p = require("sexpr-plus").parse;`, then

<!-- !test in basics -->

```js
p('')
p('; comment')
p('a')
p('"i am a string"')
p('()')
p('(a b)')
```

<!-- !test out basics -->

```json
null
null
{
  "type": "atom",
  "content": "a"
}
{
  "type": "string",
  "content": "i am a string"
}
{
  "type": "list",
  "content": []
}
{
  "type": "list",
  "content": [
    {
      "type": "atom",
      "content": "a"
    },
    {
      "type": "atom",
      "content": "b"
    }
  ]
}
```

The quoting operators become atoms of the appropriate name:

<!-- !test in basic quoting -->

```js
p("'a")
```

<!-- !test out basic quoting -->

```json
{
  "type": "list",
  "content": [
    {
      "type": "atom",
      "content": "quote"
    },
    {
      "type": "atom",
      "content": "a"
    }
  ]
}
```

<!-- !test in quoting -->


```js
p("`(,a ,@b)")
```

<!-- !test out quoting -->

```json
{
  "type": "list",
  "content": [
    {
      "type": "atom",
      "content": "quasiquote"
    },
    {
      "type": "list",
      "content": [
        {
          "type": "list",
          "content": [
            {
              "type": "atom",
              "content": "unquote"
            },
            {
              "type": "atom",
              "content": "a"
            }
          ]
        },
        {
          "type": "list",
          "content": [
            {
              "type": "atom",
              "content": "unquote-splicing"
            },
            {
              "type": "atom",
              "content": "b"
            }
          ]
        }
      ]
    }
  ]
}
```

Comments are (currently) not exposed in the output.

#### License

[MIT][4].

[1]: https://travis-ci.org/anko/sexpr-plus
[2]: https://github.com/anko/eslisp
[3]: https://github.com/fwg/s-expression
[4]: LICENSE
