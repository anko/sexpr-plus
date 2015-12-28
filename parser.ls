'use strict'

export class SyntaxError extends Error
    (message, @expected, @found, loc) ->
        @location = loc
        @message = "At line #{loc.line}, column #{loc.column}: #message"
        if Error.captureStackTrace?
            Error.captureStackTrace this, @constructor
    name: 'SyntaxError'

esc = (str) ->
    str
        .replace /[\\"\x08\t\r\f\n]/g, ->
            switch it
                | '\\' => '\\\\'
                | '"'  => '\\"'
                | '\b' => '\\b'
                | '\t' => '\\t'
                | '\n' => '\\n'
                | '\f' => '\\f'
                | '\r' => '\\r'
        .replace /[\x00-\x07\x0B\x0E\x0F]/g, -> 'x0' + it.charCodeAt 0
        .replace /[\x10-\x1F\x80-\xFF]/g, -> 'x' + it.charCodeAt 0
        .replace /[\u0100-\u0FFF]/g, -> 'u0' + it.charCodeAt 0
        .replace /[\u1000-\uFFFF]/g, -> 'u' + it.charCodeAt 0

unchars = (.join '')
pipe = (f) -> -> f ...; it

# Either whitespace or a metacharacter. `(a'b)` is parsed as `(a 'b)`, etc.
# Also, this handles the case of a list immediately following an atom,
# without whitespace in between.
isAtomEnd = -> /[\r\n\u2028\u2029 \t;\)"'`,]/.test it

export parse = (source) ->
    index = 0
    length = source.length
    line = column = 1
    locations = []
    envs = []

    createLoc = -> {offset: index, line, column}

    location = createLoc >> pipe locations~push
    start = envs~push >> location
    end = pipe envs~pop

    node = (type, content) -->
        {type, content, location: {start: locations.pop!, end: createLoc!}}

    string = node 'string'
    atom = node 'atom'
    list = node 'list'

    hasNext = -> index < length
    current = -> source[index]
    generate = (cond, f, ignore) ->
        while (ignore or hasNext!) and not cond current! => f!

    fail = (message, expected, found) !->
        loc = createLoc!
        message = "At line #{loc.line}, column #{loc.column}: #message"
        throw new SyntaxError message, expected, found, loc

    unexpectedIf = (cond) -> current >> !->
        fail "Unexpected character: #{esc it}", void, it if cond it

    expectNext = !->
        unless hasNext!
            env = envs.pop!
            extra = if env? then " (#env)" else ''
            fail "Unexpected end of source#extra", void, '<EOS>'

    skipNewline = !->
        line++
        column := 1
        index++ if source[index++] == '\r' and hasNext! and current! == '\n'

    move = -> column++; index++

    isWhitespace = -> current! in ['\r', '\n', '\u2028', '\u2029']

    next = ->
        expectNext!
        if isWhitespace!
            skipNewline!
            '\n'
        else
            source[move!]

    lookahead = ->
        move! if res = hasNext! and source[index + 1] == it
        res

    expect = !->
        expectNext!
        ch = current!
        fail "Expected #{esc it}, found #{esc ch}", it, ch if it != ch
        move!

    skipWhitespace = ->
        while hasNext!
            if isWhitespace!
                skipNewline!
            else if current! in [' ', '\t']
                move!
            else if current! == ';'
                while hasNext! and next! != '\n' => # do nothing
            else
                break

        hasNext!

    parseQuoted = (pipe location) >> (-> it!) >> (pipe next) >> (quote) ->
        # Duplicate the top. The same location is used for the list and atom.
        locations.push locations[*-1]
        list [(atom quote), parseExpr!]

    wrapped = (env, left, right, type, f) -> ->
        start env
        expect left
        ret = f!
        expect right
        end type ret

    parseList = wrapped 'unclosed list', '(', ')', list, skipWhitespace >> ->
        generate (== ')'), (parseExpr >> pipe skipWhitespace), true

    # JavaScript's escape sequences for strings
    hex = ->
        switch next!
            | '0' => 0 | '1' => 1 | '2' => 2 | '3' => 3 | '4' => 4
            | '5' => 5 | '6' => 6 | '7' => 7 | '8' => 8 | '9' => 9
            | 'A', 'a' => 10
            | 'B', 'b' => 11
            | 'C', 'c' => 12
            | 'D', 'd' => 13
            | 'E', 'e' => 14
            | 'F', 'f' => 15
            | _ => fail "Expected a hex digit, found #that", 'hex digit', that

    parseUnicodeEscape = ->
        if current! == '{'
            expect '{'
            # The largest Unicode point is U+10FFF, which has 5 hex digits. Any
            # more here is rejected. A minimum of one digit is required.
            code = hex!
            i = 0
            while current! != '}' and i < 4, i++ => code = code .<<. 4 .|. hex!
            expect '}'
        else
            code = hex! .<<. 12 .|. hex! .<<. 8 .|. hex! .<<. 4 .|. hex!

        if code > 0x10fff
            fail "Unicode point too large: #code", void, "#code"
        else if code > 0xffff
            # https://mathiasbynens.be/notes/javascript-encoding#surrogate-formulae
            code -= 0x10000
            hi = (code .>>. 10) + 0xd800
            lo = code % 0x400 + 0xdc00
            String.fromCharCode hi, lo
        else
            String.fromCharCode code

    parseEscape = end . next >> ->
        switch it
            | '0' => '\0'
            | 'b' => '\b'
            | 'f' => '\f'
            | 'n' => '\n'
            | 'r' => '\r'
            | 't' => '\t'
            | 'v' => '\v'

            | 'x' =>
                envs.push 'incomplete escape'
                String.fromCharCode hex! .<<. 4 .|. hex!

            | 'u' =>
                envs.push 'incomplete escape'
                parseUnicodeEscape!

            | _ => that

    readStringChar = next >> -> if it == '\\' then parseEscape! else it

    parseString = wrapped 'unclosed string', '"', '"', string, ->
        unchars generate (== '"'), readStringChar

    parseAtom = location >> (unexpectedIf isAtomEnd) >> ->
        atom unchars generate isAtomEnd, readStringChar

    splicingType = -> if lookahead '@' then 'unquote-splicing' else 'unquote'

    parseExpr = skipWhitespace >> expectNext >> ->
        switch current!
            | '('  => parseList!
            | '\'' => parseQuoted -> 'quote'
            | '`'  => parseQuoted -> 'quasiquote'
            | ','  => parseQuoted splicingType
            | '"'  => parseString!
            | _    => parseAtom!

    unless skipWhitespace! then null else
        do parseExpr >> pipe unexpectedIf skipWhitespace
