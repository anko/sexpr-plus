'use strict';
var Parsimmon = require("parsimmon");
var regex = Parsimmon.regex;
var string = Parsimmon.string;
var whitespace = Parsimmon.whitespace;
var lazy = Parsimmon.lazy;
var seq = Parsimmon.seq;
var alt = Parsimmon.alt;
var eof = Parsimmon.eof;

var toStringNode = function(node) {
  return {
    type : "string",
    content : node.value.join(""),
    location : {
      start : node.start,
      end : node.end
    }
  };
};
var toAtomNode = function(node) {

  var d = node.value;

  return {
    type : "atom",
    content : d.join ? d.join("") : d,
    location : {
      start : node.start,
      end : node.end
    }
  };
};
var toListNode = function(node) {
  return {
    type : "list",
    content : node.value,
    location : {
      start : node.start,
      end : node.end
    }
  };
};

var endOfLineComment = regex(/;[^\n]*/).skip(alt(string("\n"), eof))
  .desc("end-of-line comment");

var optWhitespace = alt(endOfLineComment, whitespace).many();

var lexeme = function(p) { return p.skip(optWhitespace); };

var escapedSpecialChar = string('\\')
  .then(alt(
        string("b"),
        string("f"),
        string("n"),
        string("r"),
        string("t"),
        string("v"),
        string("0")))
  .map(function(c) {
    switch (c) {
      case "b": return "\b";
      case "f": return "\f";
      case "n": return "\n";
      case "r": return "\r";
      case "t": return "\t";
      case "v": return "\v";
      case "0": return "\0";
    }
  });
var stringDelimiter = string('"');

var stringLiteral = lexeme((function() {
    var escapedChar = string("\\").then(regex(/["\\]/));
    var normalChar = regex(/[^"\\]/);
    return stringDelimiter.desc("string-opener")
        .then(
            alt(normalChar, escapedChar, escapedSpecialChar)
            .desc("string content").many())
        .skip(stringDelimiter.desc("string-terminator"))
        .mark()
        .map(toStringNode);
})());

var atom = lexeme((function() {
    var escapedChar = string('\\').then(regex(/[;"'`,\\()\n\t\r ]/));
    var normalChar = regex(/[^;"'`,\\()\n\t\r ]/);
    return alt(normalChar, escapedChar).atLeast(1).mark()
        .map(toAtomNode).desc("atom");
})());

var lparen = lexeme(string('(')).desc("opening paren");
var rparen = lexeme(string(')')).desc("closing paren");
var expr = lazy("sexpr", function() { return alt(list, atom, stringLiteral, quotedExpr); });

var quoteMap = {
    '\'' : 'quote',
    '`'  : 'quasiquote',
    ','  : 'unquote',
    ',@' : 'unquote-splicing'
};
var quote  = lexeme(regex(/('|`|,@|,)/)).desc("a quotation operator")
  .map(function(d) { return quoteMap[d]; })
  .mark()
  .map(toAtomNode);
var quotedExpr = quote.chain(function(quoteResult) {

  return expr.mark().map(function(exprResult) {

    var node = {
      value : [ quoteResult, exprResult.value ],
      start : quoteResult.start,
      end : exprResult.end
    };

    return toListNode(node);
  });

}).desc("a quoted form");

var list = lparen.then(expr.many()).skip(rparen).mark().map(toListNode);

var shebangLine = regex(/^#![^\n]*/).skip(alt(string("\n"), eof)).desc("shebang line");

var parse = function(stream) {
    //var s = optWhitespace.then(expr.or(optWhitespace)).parse(stream);
    var s = shebangLine.atMost(1)
      .then(optWhitespace).then(expr.many()).parse(stream);
    if (s.status) return s.value;
    else {

        var streamSoFar = stream.slice(0, s.index);
        var line = 1 + (streamSoFar.match(/\n/g) || []).length; // Count '\n's
        var col = streamSoFar.length - streamSoFar.lastIndexOf("\n");

        var e = new Error("Syntax error at position " + s.index + ": " +
                          "(expected " + s.expected.join(" or ") + ")");
        if (s.expected.indexOf("string-terminator") >= 0)
            e.message = "Syntax error: Unterminated string literal";
        e.line = line;
        e.col = col;
        throw e;
    }
};
module.exports = {
  parse : parse,
  SyntaxError : Error
}
