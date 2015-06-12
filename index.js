'use strict';
var Parsimmon     = require("parsimmon");
var regex         = Parsimmon.regex;
var string        = Parsimmon.string;
var optWhitespace = Parsimmon.optWhitespace;
var lazy          = Parsimmon.lazy;
var seq           = Parsimmon.seq;
var alt           = Parsimmon.alt;
var eof           = Parsimmon.eof;

var comment = optWhitespace.then(string(";")).then(regex(/.*/)).skip(string("\n").or(eof)).skip(optWhitespace);

var lexeme = function(p) { return p.skip(comment.atLeast(1).or(optWhitespace)); };

var stringLiteral = lexeme((function() {
    var escapedChar = string("\\").then(regex(/["\\]/));
    var normalChar = string("\\").atMost(1).then(regex(/[^"\\]/));
    return string('"').desc("string-opener")
        .then(normalChar.or(escapedChar).desc("string content").many())
        .skip(string('"').desc("string-terminator"))
        .map(function(s) { return new String(s.join("")); });
})());

var regexLiteral = lexeme((function() {
    var escapedChar = string("\\").then(regex(/[\\\/]/));
    var normalChar = string("\\").atMost(1).then(regex(/[^\\\/]/));
    return string('/').desc("regex-opener")
        .then(seq(
            alt(normalChar, escapedChar).desc("regex content").many(),
            string('/').desc("regex-terminator"),
            regex(/[a-zA-Z]*/)))
        .map(function(s) {
            var content = s[0].join("");
            // s[1] is just the in-between slash
            var flags   = s[2];
            return new RegExp(content, flags);
        });
})());

var atom = lexeme((function() {
    var escapedChar = string('\\').then(regex(/['"\\;]/));
    var legalChar = regex(/[^;\s"/`,'()]/);
    var normalChar  = string('\\').atMost(1).then(legalChar);
    return normalChar.or(escapedChar).atLeast(1)
        .map(function(d) {
            return d.join("");
        }).desc("atom");
})());

var lparen = lexeme(string('(')).desc("opening paren");
var rparen = lexeme(string(')')).desc("closing paren");
var expr = lexeme(lazy("sexpr", function() {
    return alt(form, atom, quotedExpr);
}));

var quote  = lexeme(regex(/('|`|,@|,)/)).desc("a quote");
var quotedExpr = quote.chain(function(quoteResult) {

    var quoteMap = {
        '\'' : 'quote',
        '`'  : 'quasiquote',
        ','  : 'unquote',
        ',@' : 'unquote-splicing'
    }

    return expr.map(function(exprResult) {
        return [ quoteMap[quoteResult] , exprResult ];
    });
});
var atom = alt(stringLiteral, regexLiteral, atom);
var form = lparen.then(expr.many()).skip(rparen);

module.exports = function(stream) {
    var s = optWhitespace.then(alt(expr, optWhitespace)).parse(stream);
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
        return e;
    }
};
module.exports.SyntaxError = Error;
