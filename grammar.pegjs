{
  function extractList(list, index) {
    var result = [], i;

    for (i = 0; i < list.length; i++) {
      if (list[i][index] !== null) {
        result.push(list[i][index]);
      }
    }

    return result;
  }

  function buildList(first, rest, index) {
    return (first !== null ? [first] : []).concat(extractList(rest, index));
  }
}

start = _ f:form? _ { return f }


EOF = !.
whitespace "whitespace" = ( " " / "\t" / "\n" / "\r" )+
endOfLineComment "comment" = ";" [^\n]* ("\n" / EOF)
__ = endOfLineComment / whitespace
_  = __*


form = it:(list / atom / string / quotedForm) { return it; }

quotedForm = q:quote f:form { return [ q, f ] }


list = _ "(" _ c:listContents _ ")" _ { return c; }
listContents "list contents"
  = first:form? rest:( _ form )* { return buildList(first, rest, 1); }

quote
  = "'"  { return "quote" }
  / "`"  { return "quasiquote" }
  / ",@" { return "unquote-splicing" }
  / ","  { return "unquote" }


string =
  _ stringDelimiter c:stringContents stringDelimiter _ { return new String(c.join("")) }

stringDelimiter = '"'
stringContents = ( stringChar / stringEscapedChar )*

stringEscapedChar = "\\" c:stringCharNeedingEscape { return c; }
stringCharNeedingEscape = ["\\]
stringChar             = [^"\\]


atom = _ c:(atomChar / atomEscapedChar)+ _ { return c.join(""); }

atomEscapedChar = s:"\\" c:atomCharNeedingEscape { return c; }
atomCharNeedingEscape = [;"'`,\\()\n\t\r ]
atomChar             = [^;"'`,\\()\n\t\r ]
