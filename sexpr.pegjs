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

start = form


whitespace       = ( " " / "\t" / "\n" / "\r" )+
optWhitespace    = ( " " / "\t" / "\n" / "\r" )*
endOfLineComment = ";" .* "\n"
__ = endOfLineComment / whitespace
_  = __?


form = _ it:(list / atom / string) _ { return it; }


list = _ "(" _ c:listContents _ ")" _ { return c; }
listContents "list contents"
  = first:form? rest:( _ form )* { return buildList(first, rest, 1); }


string =
  _ stringDelimiter c:stringContents stringDelimiter _ { return new String(c) }

stringDelimiter = '"'
stringContents = ( stringChar / stringEscapedChar )*

stringEscapedChar = "\\" stringCharNeedingEscape
stringCharNeedingEscape = ["\\]
stringChar             = [^"\\]


atom = _ c:(atomChar / atomEscapedChar)+ _ { return c.join(""); }

atomEscapedChar = "\\" atomCharNeedingEscape
atomCharNeedingEscape = [;"'`,\() ]
atomChar             = [^;"'`,\() ]
