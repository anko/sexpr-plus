require! {
  tape
  './parser.ls': {parse}: sexpr
}

test = (name, func) ->
  tape name, (t) ->
    func.call t   # Make `this` refer to tape's asserts
    t.end!        # Automatically end tests

# Because writing out all the '{ type : \list content : [ ... ]  }' stuff would
# be boring and unreadable, here's a dead simple DSL for simplifying that.
convert = ->
  | not it? => null
  | Array.isArray it => type : \list content : it.map convert
  | typeof it == \string => type : \atom   content : it
  | it instanceof String => type : \string content : it.to-string!
  | otherwise =>
    throw Error "Test error; invalid convenience template (got #it)"

delete-location-data = ->
  if it is null then return it

  delete it.location
  if it.type is \list then it.content.for-each delete-location-data
  return it

to = (input, output, description) -->
  output = convert output
  test description, ->
    input
    |> parse
    |> delete-location-data
    |> @deep-equals _, output

#
# Basics
#

''    `to` null          <| "empty input"
' \t' `to` null          <| "empty input (just whitespace)"
'a'   `to` \a            <| "atom"
'"a"' `to` new String \a <| "string"
'()'  `to` []            <| "empty list"
' a ' `to` \a            <| "whitespace is insignificant"
'((a b c)(()()))'   `to` [[\a \b \c] [[] []]] <| "nested lists"
'((a b c) (() ()))' `to` [[\a \b \c] [[] []]] <| "nested lists with spacing"

'(a\nb)' `to` [\a \b] <| "newlines are not part of atoms"

# String/atom hex escapes

hex = [[x, +x] for x in '123456789'] ++
  [[x, i + 10] for x, i in 'abcdef'] ++
  [[x, i + 10] for x, i in 'ABCDEF']

test 'ascii escapes work with atoms' ->
  esc = (x, y) ~>
    @deep-equals do
      (delete-location-data parse x)
      {type : \atom content : String.from-char-code y}
      "`#x`"

  '\\x00' `esc` 0

  for [l, c] in hex
    "\\x0#{l}" `esc` (c)
    "\\x#{l}0" `esc` (c * 0x10)
    "\\x1#{l}" `esc` (0x10 + c)
    "\\x#{l}1" `esc` (c * 0x10 + 1)
    "\\x#{l}f" `esc` (c * 0x10 + 15)

test 'unicode escapes work with atoms' ->
  esc = (x, y) ~>
    @deep-equals do
      (delete-location-data parse x)
      {type : \atom content : String.from-char-code y}
      "`#x`"

  '\\u0000' `esc` 0

  for [l, c] in hex
    "\\u000#{l}" `esc` (c)
    "\\u00#{l}0" `esc` (c * 0x10)
    "\\u0#{l}00" `esc` (c * 0x100)
    "\\u#{l}000" `esc` (c * 0x1000)
    "\\u001#{l}" `esc` (0x10 + c)
    "\\u011#{l}" `esc` (0x110 + c)
    "\\u111#{l}" `esc` (0x1110 + c)
    "\\ufff#{l}" `esc` (0xfff0 + c)
    "\\uFFF#{l}" `esc` (0xFFF0 + c)

test 'ascii escapes work with strings' ->
  esc = (x, y) ~>
    @deep-equals do
      (delete-location-data parse "\"#x\"")
      {type : \string content : String.from-char-code y}
      "`\"#x\"`"

  '\\x00' `esc` 0

  for [l, c] in hex
    "\\x0#{l}" `esc` (c)
    "\\x#{l}0" `esc` (c * 0x10)
    "\\x1#{l}" `esc` (0x10 + c)
    "\\x#{l}1" `esc` (c * 0x10 + 1)
    "\\x#{l}f" `esc` (c * 0x10 + 15)

test 'unicode escapes work with strings' ->
  esc = (x, y) ~>
    @deep-equals do
      (delete-location-data parse "\"#x\"")
      {type : \string content : String.from-char-code y}
      "`\"#x\"`"

  '\\u0000' `esc` 0

  for [l, c] in hex
    "\\u000#{l}" `esc` (c)
    "\\u00#{l}0" `esc` (c * 0x10)
    "\\u0#{l}00" `esc` (c * 0x100)
    "\\u#{l}000" `esc` (c * 0x1000)
    "\\u001#{l}" `esc` (0x10 + c)
    "\\u011#{l}" `esc` (0x110 + c)
    "\\u111#{l}" `esc` (0x1110 + c)
    "\\ufff#{l}" `esc` (0xfff0 + c)
    "\\uFFF#{l}" `esc` (0xFFF0 + c)

test 'Unicode brace escapes work with strings' ->
  esc = (x, y) ~>
    @deep-equals do
      (delete-location-data parse "\"#x\"")
      {type : \string content : String.from-char-code y}
      "`\"#x\"`"

  '\\u0000' `esc` 0

  for [l, c] in hex
    "\\u{#{l}}" `esc` (c)
    "\\u{#{l}0}" `esc` (c * 0x10)
    "\\u{#{l}00}" `esc` (c * 0x100)
    "\\u{1#{l}}" `esc` (0x10 + c)
    "\\u{11#{l}}" `esc` (0x110 + c)
    "\\u{ff#{l}}" `esc` (0xff0 + c)
    "\\u{FF#{l}}" `esc` (0xFF0 + c)
    "\\u{000#{l}}" `esc` (c)
    "\\u{00#{l}0}" `esc` (c * 0x10)
    "\\u{0#{l}00}" `esc` (c * 0x100)
    "\\u{#{l}000}" `esc` (c * 0x1000)
    "\\u{001#{l}}" `esc` (0x10 + c)
    "\\u{011#{l}}" `esc` (0x110 + c)
    "\\u{111#{l}}" `esc` (0x1110 + c)
    "\\u{fff#{l}}" `esc` (0xfff0 + c)
    "\\u{FFF#{l}}" `esc` (0xFFF0 + c)

#
# Quoting operators
#

[ <[' quote]> <[` quasiquote]> <[, unquote]> <[,@ unquote-splicing]> ]
  .for-each ([c, name]) ->
    "#{c}a"      `to` [name, \a]              <| "#name'd atom"
    "#c\"a\""    `to` [name, new String \a]   <| "#name'd string"
    "#c()"       `to` [name, []]              <| "#name'd empty list"
    "#c(a b c)"  `to` [name, [\a \b \c]]      <| "#name'd list with contents"
    "(#{c}a)"    `to` [[name, \a]]            <| "#name'd atom in a list"
    "(a #c b)"   `to` [\a [name, \b]]         <| "whitespaced #name"
    "(a #c#c b)" `to` [\a [name, [name, \b]]] <| "consecutive #{name}s nest"
    "(a#{c}b)"   `to` [\a [name, \b]]         <| "#name acts as delimiter"

    test "#name with nothing to apply to is an error" ->
      (-> parse "(#c)") `@throws` sexpr.SyntaxError

#
# Special characters and escaping
#

char-escape = ->
  switch it
  | \\n => "\\n"
  | \\t => "\\t"
  | \\r => "\\r"
  | _   => it

[ "'" '`' '"' ';' '\\' " " '"' "\n" "\t" ] .for-each (c) ->
  "a\\#{c}b" `to` "a#{c}b"
    <| "escaped #{char-escape c} in an atom should parse"

[ \" "\\" ] .for-each (c) ->
  "\"a\\#{c}b\"" `to` new String "a#{c}b"
    <| "escaped #{char-escape c} in a string should parse"

[ [\b "\b"] [\f "\f"] [\n "\n"] [\r "\r"] [\t "\t"] [\v "\v"] [\0 "\0"] ]
  .for-each ([char, escapedChar]) ->
    "\"a\\#{char}b\"" `to` new String "a#{escapedChar}b"
    <| "strings may contain \\#{char} escape"

test "special characters work" ->
  <[ + / * £ $ % ^ & あ ]>.for-each ->
    it `to` it <| "special character #it works as atom"

#
# Comments
#

";hi" `to` null           <| "only 1 comment"
";hi\n;yo" `to` null      <| "only comments"
"(\n; a\n;b\n\n)" `to` [] <| "empty list with comments inside"
"();hi" `to` []           <| "comment immediately following list"
"a;hi" `to` "a"           <| "comment immediately following atom"
";(a comment)" `to` null  <| "comment looking like a form"
"(a ;)\nb)" `to` [\a \b]  <| "form with close-paren-looking comment between"
'("a ;)"\n)' `to` [new String "a ;)"] <| "can't start comment in string"

#
# Location information
#

test "lone atom loc is correct" ->
  parse "hi"
    ..type `@equals` \atom
    ..location
      ..start
        ..offset `@equals` 0
        ..line   `@equals` 1
        ..column `@equals` 1
      ..end
        ..offset `@equals` 2
        ..line   `@equals` 1
        ..column `@equals` 3

test "single-line string loc is correct" ->
  parse '"hi"'
    ..type `@equals` \string
    ..location
      ..start
        ..offset `@equals` 0
        ..line   `@equals` 1
        ..column `@equals` 1
      ..end
        ..offset `@equals` 4
        ..line   `@equals` 1
        ..column `@equals` 5

test "multi-line string loc is correct" ->
  parse '"hi\nthere"'
    ..type `@equals` \string
    ..location
      ..start
        ..offset `@equals` 0
        ..line   `@equals` 1
        ..column `@equals` 1
      ..end
        ..offset `@equals` 10
        ..line   `@equals` 2
        ..column `@equals` 7

test "string containing escapes has correct loc" ->
  parse '"\\n\\t"'
    ..type `@equals` \string
    ..location
      ..start
        ..offset `@equals` 0
        ..line   `@equals` 1
        ..column `@equals` 1
      ..end
        ..offset `@equals` 6
        ..line   `@equals` 1
        ..column `@equals` 7

test "empty list loc is correct" ->
  parse '()'
    ..type `@equals` \list
    ..location
      ..start
        ..offset `@equals` 0
        ..line   `@equals` 1
        ..column `@equals` 1
      ..end
        ..offset `@equals` 2
        ..line   `@equals` 1
        ..column `@equals` 3

test "2-element list loc is correct" ->
  parse '(a b)'
    ..type `@equals` \list
    ..location
      ..start
        ..offset `@equals` 0
        ..line   `@equals` 1
        ..column `@equals` 1
      ..end
        ..offset `@equals` 5
        ..line   `@equals` 1
        ..column `@equals` 6

test "2-element list content loc is correct" ->
  parse '(a b)'
    ..type `@equals` \list
    ..content
      ..0
        ..type `@equals` \atom
        ..location
          ..start
            ..offset `@equals` 1
            ..line   `@equals` 1
            ..column `@equals` 2
          ..end
            ..offset `@equals` 2
            ..line   `@equals` 1
            ..column `@equals` 3
      ..1
        ..type `@equals` \atom
        ..location
          ..start
            ..offset `@equals` 3
            ..line   `@equals` 1
            ..column `@equals` 4
          ..end
            ..offset `@equals` 4
            ..line   `@equals` 1
            ..column `@equals` 5

test "quote atom loc matches that of the quote character" ->
  [ <[' quote]> <[` quasiquote]> <[, unquote]> <[,@ unquote-splicing]> ]
    .for-each ([c, name]) ~>
      parse "#{c}a"
        ..type `@equals` \list
        ..content.0
          ..type `@equals` \atom
          ..content `@equals` name
          ..location
            ..start
              ..offset `@equals` 0
              ..line   `@equals` 1
              ..column `@equals` 1
            ..end
              ..offset `@equals` c.length
              ..line   `@equals` 1
              ..column `@equals` (1 + c.length)

#
# Form errors
#

test "closing parenthesis after the end is an error" ->
  (-> parse "()()") `@throws` sexpr.SyntaxError
  (-> parse "()a") `@throws` sexpr.SyntaxError
  (-> parse "())") `@throws` sexpr.SyntaxError

test "incomplete string is an error" ->
  (-> parse '"a') `@throws` sexpr.SyntaxError

test "incomplete form due to comment is an error" ->
  (-> parse '(a;)') `@throws` sexpr.SyntaxError
