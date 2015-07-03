sexpr = require \./index.js
{ parse } = sexpr

test = (name, func) ->
  (require \tape) name, (t) ->
    func.call t   # Make `this` refer to tape's asserts
    t.end!        # Automatically end tests

to = (input, output, description) -->
  test description, -> input |> parse |> @deep-equals _, output

''    `to` null          <| "empty input"
' \t' `to` null          <| "empty input (just whitespace)"
'a'   `to` \a            <| "atom"
'"a"' `to` new String \a <| "string"
'()'  `to` []            <| "empty list"
' a ' `to` \a            <| "whitespace is insignificant"
'((a b c)(()()))'   `to` [[\a \b \c] [[] []]] <| "nested lists"
'((a b c) (() ()))' `to` [[\a \b \c] [[] []]] <| "nested lists with spacing"

'(a\nb)' `to` [\a \b] <| "newlines are not part of atoms"

[ [\' \quote] [\` \quasiquote] [\, \unquote] [\,@ \unquote-splicing] ]
  .for-each ([c, name]) ->
    "#{c}a"      `to` [name, \a]              <| "#name'd atom"
    "#c\"a\""    `to` [name, new String \a]   <| "#name'd string"
    "#c()"       `to` [name, []]              <| "#name'd empty list"
    "#c(a b c)"  `to` [name, [\a \b \c]]      <| "#name'd list with contents"
    "(#{c}a)"    `to` [[name, \a]]            <| "#name'd atom in a list"
    "(a #c b)"   `to` [\a [name, \b]]         <| "whitespaced #name"
    "(a #c#c b)" `to` [\a [name, [name, \b]]] <| "consecutive #{name}s nest"
    "(a#{c}b)"   `to` [\a [name, \b]]         <| "#{name} acts as delimiter"

    test "#name with nothing to apply to is an error" ->
      (-> parse "(#c)") `@throws` sexpr.SyntaxError

test "stuff after the end is an error" ->
  [ "()" "a" ")" ].for-each ~> (-> parse "()#it") `@throws` sexpr.SyntaxError


char-escape = ->
  switch it
  | \\n => "\\n"
  | \\t => "\\t"
  | \\r => "\\r"
  | _   => it

[ \' \` \" \; \\ " " '"' "\n" "\t" ] .for-each (c) ->
  "a\\#{c}b" `to` "a#{c}b"
    <| "escaped #{char-escape c} in an atom should parse"

[ \" "\\" ] .for-each (c) ->
  "\"a\\#{c}b\"" `to` new String "a#{c}b"
    <| "escaped #{char-escape c} in a string should parse"

test "special characters work" ->
  <[ + / * £ $ % ^ & あ ]>.for-each ->
    it `to` it <| "special character #it works as atom"

";hi" `to` null           <| "only 1 comment"
";hi\n;yo" `to` null      <| "only comments"
"(\n; a\n;b\n\n)" `to` [] <| "empty list with comments inside"
"();hi" `to` []           <| "comment immediately following list"
"a;hi" `to` "a"           <| "comment immediately following atom"
";(a comment)" `to` null  <| "comment looking like a form"
"(a ;)\nb)" `to` [\a \b]  <| "form with close-paren-looking comment between"
'("a ;)"\n)' `to` [new String "a ;)"] <| "can't start comment in string"

test "incomplete string is an error" ->
  (-> parse '"a') `@throws` sexpr.SyntaxError

test "incomplete form due to comment is an error" ->
  (-> parse '(a;)') `@throws` sexpr.SyntaxError
