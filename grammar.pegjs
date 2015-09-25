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

  function outputString(content) {
    return {
      type : "string",
      content : content
    };
  }

  function outputAtom(content) {
    return {
      type : "atom",
      content : content
    };
  }

  function outputList(content) {
    return {
      type : "list",
      content : content
    };
  }
}

start = _ f:form? _ { return f }


EOF = !.
whitespace "whitespace" = ( " " / "\t" / "\n" / "\r" )+
endOfLineComment "comment" = ";" [^\n]* ("\n" / EOF)
__ = endOfLineComment / whitespace
_  = __*


form = it:(list / atom / string / quotedForm) { return it; }

quotedForm = q:quote f:form { return outputList([ q, f ]) }


list = _ "(" _ c:listContents _ ")" _ { return c; }
listContents "list contents"
  = first:form? rest:( _ form )* { return outputList(buildList(first, rest, 1)); }

quote
  = "'"  { return outputAtom("quote") }
  / "`"  { return outputAtom("quasiquote") }
  / ",@" { return outputAtom("unquote-splicing") }
  / ","  { return outputAtom("unquote") }


string =
  _ stringDelimiter c:stringContents stringDelimiter _ { return outputString(c.join("")) }

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

atom = _ c:(atomChar / atomEscapedChar)+ _ { return outputAtom(c.join("")); }

atomEscapedChar = s:"\\" c:atomCharNeedingEscape { return c; }
atomCharNeedingEscape = [;"'`,\\()\n\t\r ]
atomChar             = [^;"'`,\\()\n\t\r ]
