'use strict';
var Parsimmon = require("parsimmon");
var regex = Parsimmon.regex;
var string = Parsimmon.string;
var lazy = Parsimmon.lazy;
var seq = Parsimmon.seq;
var alt = Parsimmon.alt;
var eof = Parsimmon.eof;
var succeed = Parsimmon.succeed;

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

var construct = function() {

var openParenChar = string("(");
var closeParenChar = string(")");
var commentChar = string(";");
var escapeChar = string('\\');
var stringDelimiterChar = string('"');
var quoteChar = string("'");
var quasiquoteChar = string("`");
var unquoteChar = string(",");
var unquoteSplicingModifierChar = string("@");
var whitespaceChar = regex(/\s/);
var whitespace = whitespaceChar.atLeast(1);

var endOfLineComment = commentChar
  .then(regex(/[^\n]*/))
  .skip(alt(string("\n"), eof))
  .desc("end-of-line comment");

var optWhitespace = alt(endOfLineComment, whitespace).many();
var lexeme = function(p) { return p.skip(optWhitespace); };

var singleCharEscape = escapeChar
  .then(alt(
        string("b"),
        string("f"),
        string("n"),
        string("r"),
        string("t"),
        string("v"),
        string("0"),
        escapeChar))
  .map(function(c) {
    switch (c) {
      case "b": return "\b";
      case "f": return "\f";
      case "n": return "\n";
      case "r": return "\r";
      case "t": return "\t";
      case "v": return "\v";
      case "0": return "\0";
      default : return c;
    }
  });


var charNot = function() {

  var args = [].slice.call(arguments);

  return Parsimmon.custom(function(success, failure) {
    return function(stream, i) {

      var someParserMatches = args.some(function(p) {
        return p._(stream, i).status;
      });

      //console.log(someParserMatches, stream, i);

      if ((! someParserMatches) && (i < stream.length)) {
        return success(i+1, stream.charAt(i));
      } else {
        return failure(i, "anything that doesn't match " + args);
      }
    };
  });
};

var stringParser = (function() {

  var delimiter = stringDelimiterChar;

  var escapedDelimiter = escapeChar.then(delimiter);
  var escapedChar = alt(escapedDelimiter, singleCharEscape);

  var normalChar = charNot(delimiter, escapeChar);

  var character = alt(normalChar, escapedChar);

  var content = character.many().desc("string content");

  var main = lexeme(
    (delimiter.desc("string-opener"))
      .then(content)
      .skip(delimiter.desc("string-terminator"))
      .mark()
      .map(toStringNode)
      .desc("string literal")
  );

  return {
    main : main,
    sub : {
      delimiter : delimiter,
      escapedDelimiter : escapedDelimiter,
      escapedCharacter : escapedChar,
      normalCharacter : normalChar,
      anyCharacter : character,
      content : content
    }
  };
})();

var atomParser = (function() {

  var needEscape = [
    commentChar,
    stringDelimiterChar,
    quoteChar,
    quasiquoteChar,
    unquoteChar,
    escapeChar,
    openParenChar,
    closeParenChar,
    whitespaceChar
  ];
  var charNeedingEscape = alt.apply(null, needEscape);
  var escapedChar = escapeChar.then(charNeedingEscape);
  var normalChar = charNot(charNeedingEscape);

  var character = alt(escapedChar, normalChar);

  var main = lexeme(
    character.atLeast(1)
      .mark()
      .map(toAtomNode)
      .desc("atom")
  );
  return {
    main : main,
    sub : {
      charNeedingEscape : charNeedingEscape,
      escapedCharacter : escapedChar,
      normalCharacter : normalChar,
      anyCharacter : character
    }
  };
})();

var listOpener = lexeme(openParenChar).desc("opening paren");
var listTerminator = lexeme(closeParenChar).desc("closing paren");

var expression = lazy("expression", function() {
  return alt(
    list,
    atomParser.main,
    stringParser.main,
    quotedExpressionParser.main
  );
});

var listContent = expression.many().desc("list content");
var list = listOpener.then(listContent).skip(listTerminator)
  .mark()
  .map(toListNode);

var quotedExpressionParser = (function () {
  var quote = quoteChar
    .then(succeed("quote"))
    .mark().map(toAtomNode);
  var quasiquote = quasiquoteChar
    .then(succeed("quasiquote"))
    .mark().map(toAtomNode);
  var unquote = unquoteChar
    .then(succeed("unquote"))
    .mark().map(toAtomNode);
  var unquoteSplicing = unquoteChar.then(unquoteSplicingModifierChar)
    .then(succeed("unquote-splicing"))
    .mark().map(toAtomNode);

  var anyQuote = alt(quote, quasiquote, unquoteSplicing, unquote);

  var main = lexeme(anyQuote).chain(function(quoteResult) {
    return expression.mark().map(function(exprResult) {

      var node = {
        value : [ quoteResult, exprResult.value ],
        start : quoteResult.start,
        end : exprResult.end
      };

      return toListNode(node);
    });
  }).desc("quoted expression");

  return {
    main : main,
    sub : {
      quote,
      quasiquote,
      unquote,
      unquoteSplicing,
      anyQuote
    }
  };
})();

var shebangLine = regex(/^#![^\n]*/).skip(alt(string("\n"), eof)).desc("shebang line");

var main = shebangLine.atMost(1)
  .then(optWhitespace)
  .then(expression.many());

var replace = function(parserToReplace, parserWithNewBehaviour) {
  parserToReplace._ = parserWithNewBehaviour._;
};
var clone = function(parserToClone) {
  return Parsimmon.custom(function(success, failure) {
    return parserToClone._;
  });
};

return {
  main : main,
  replace : replace,
  clone : clone,
  parsimmon : Parsimmon,
  sub : {
    basic : {
      lexeme : lexeme,
      openParenChar : openParenChar,
      closeParenChar : closeParenChar,
      commentChar : commentChar,
      escapeChar : escapeChar,
      stringDelimiterChar : stringDelimiterChar,
      quoteChar : quoteChar,
      quasiquoteChar : quasiquoteChar,
      unquoteChar : unquoteChar,
      unquoteSplicingModifierChar : unquoteSplicingModifierChar,
      whitespaceChar : whitespaceChar,
      whitespace : whitespace,
      endOfLineComment : endOfLineComment,
      shebangLine : shebangLine,
      list : list,
      listOpener : listOpener,
      listTerminator : listTerminator,
      listContent : listContent,
      singleCharEscape : singleCharEscape,
      expression : expression,
    },
    composite : {
      atom : atomParser,
      string : stringParser,
      quotedExpression : quotedExpressionParser,
    }
  }
};

}; // end of constructor

module.exports = construct;
