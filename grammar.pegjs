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
    return (first !== null ? [first] : []) .concat(extractList(rest, index));
  }

  function outputString(content, loc) {
    return {
      type : "string",
      content : content,
      location : loc
    };
  }

  function outputAtom(content, loc) {
    return {
      type : "atom",
      content : content,
      location : loc
    };
  }

  function outputList(content, loc) {
    return {
      type : "list",
      content : content,
      location : loc
    };
  }
}

start = _ f:form* _ { return f }


EOF = !.
whitespace "whitespace" = ( " " / "\t" / "\n" / "\r" )+
endOfLineComment "comment" = ";" [^\n]* ("\n" / EOF)
__ = endOfLineComment / whitespace
_  = __*


form = it:(list / atom / string / quotedForm) { return it; }

quotedForm = q:quote f:form { return outputList([ q, f ], location()) }


list = _ "(" _ c:listContents _ ")" _ { return outputList(c, location()); }
listContents "list contents"
  = first:form? rest:( _ form )* { return buildList(first, rest, 1) }

quote
  = "'"  { return outputAtom("quote", location()) }
  / "`"  { return outputAtom("quasiquote", location()) }
  / ",@" { return outputAtom("unquote-splicing", location()) }
  / ","  { return outputAtom("unquote", location()) }


string =
  _ stringDelimiter c:stringContents stringDelimiter _ {
    return outputString(c.join(""), location())
  }

stringDelimiter = '"'
stringContents = ( stringChar / stringEscapedChar / stringEscapedSpecialChar )*

stringEscapedChar = "\\" c:stringCharNeedingEscape { return c; }
stringCharNeedingEscape = ["\\]
stringChar             = [^"\\]

/* JavaScript's single-character escape sequences */
stringEscapedSpecialCharLetter = [bfnrtv0]
stringEscapedSpecialChar = "\\" c:stringEscapedSpecialCharLetter {
  switch(c) {
    case "b": return "\b";
    case "f": return "\f";
    case "n": return "\n";
    case "r": return "\r";
    case "t": return "\t";
    case "v": return "\v";
    case "0": return "\0";
  }
}

atom = _ c:atomContents _ {
  return c;
}

atomContents = c:( atomChar / atomEscapedChar )+ {
  return outputAtom(c.join(""), location());
}

atomEscapedChar = s:"\\" c:atomCharNeedingEscape { return c; }
atomCharNeedingEscape = [;"'`,\\()\n\t\r ]
atomChar             = [^;"'`,\\()\n\t\r ]
