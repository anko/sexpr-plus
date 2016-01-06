'use strict'

export class SyntaxError extends Error
    (message, @expected, @found, loc) ->
        @location = loc
        @message = "At line #{loc.line}, column #{loc.column}: #message"
        if Error.captureStackTrace?
            Error.captureStackTrace this, @constructor
    name: 'SyntaxError'

# Escape non-ASCII or non-printable characters for more helpful error messages
# when dealing with these.
esc = (str) ->
    str
        .replace /[\\"\b\t\r\f\n]/g, ->
            switch it
                | '\\' => '\\\\'
                | '"'  => '\\"'
                | '\b' => '\\b'
                | '\t' => '\\t'
                | '\n' => '\\n'
                | '\f' => '\\f'
                | '\r' => '\\r'
        # If it's already been replaced above, it's not going to match here.
        .replace /[\x00-\x0F]/g, -> 'x0' + it.charCodeAt 0
        .replace /[\x10-\x1F\x80-\xFF]/g, -> 'x' + it.charCodeAt 0
        .replace /[\u0100-\u0FFF]/g, -> 'u0' + it.charCodeAt 0
        .replace /[\u1000-\uFFFF]/g, -> 'u' + it.charCodeAt 0

class Parser
    (@source) ->
        @index = 0
        @line = @column = 1
        @locations = []
        @envs = []

    createLoc: -> {offset: @index, @line, @column}

    location: ->
        @locations.push loc = @createLoc!
        loc

    start: (env) ->
        @envs.push env
        @location!

    end: ->
        @envs.pop!
        it

    node: (type, content) ->
        type: type
        content: content
        location:
            # Pull this info automatically. Less repetitive
            start: @locations.pop!
            end: @createLoc!

    string: (content) -> @node 'string', content
    atom: (content) -> @node 'atom', content
    list: (content) -> @node 'list', content

    hasNext: -> @index < @source.length
    current: -> @source[@index]

    fail: (message, expected, found) !->
        throw new SyntaxError message, expected, found, @createLoc!

    expectNext: !->
        unless @hasNext!
            env = @envs.pop!
            extra = if env? then " (#env)" else ''
            @fail "Unexpected end of source#extra", void, '<EOS>'

    skipNewline: !->
        @line++
        @column = 1
        if @source[@index++] == '\r' and @hasNext! and @current! == '\n'
            @index++

    move: -> @column++; @index++

    isNewline: -> @current! in ['\r', '\n', '\u2028', '\u2029']

    next: ->
        @expectNext!
        if @isNewline!
            @skipNewline!
            '\n'
        else
            @source[@move!]

    lookahead: (token) ->
        if res = @hasNext! and @source[@index + 1] == token
            @move!
        res

    expect: (token) !->
        @expectNext!
        ch = @current!
        unless token == ch
            @fail "Expected #{esc token}, found #{esc ch}", token, ch
        @move!

    skipWhitespace: ->
        while @hasNext!
            if @isNewline!
                @skipNewline!
            else if @current! in [' ', '\t']
                @move!
            else if @current! == ';'
                while @hasNext! and @next! != '\n' => # do nothing
            else
                break

        @hasNext!

    # The same location is used for the list and atom, so it needs duplicated.
    prepareQuotedLoc: !->
        @location!
        @location!

    parseQuoted: (quote) ->
        @next!
        @list [(@atom quote), @parseExpr!]

    parseList: ->
        @start 'unclosed list'
        @expect '('
        @skipWhitespace!

        ret = []
        until @current! == ')'
            ret.push @parseExpr!
            @skipWhitespace!

        @expect ')'

        @end @list ret

    # JavaScript's escape sequences for strings.

    # Eat a single hex character, and return the numeric equivalent. A giant
    # switch case is both faster and easier than a hash.
    hex: ->
        switch @next!
            | '0' => 0 | '1' => 1 | '2' => 2 | '3' => 3 | '4' => 4
            | '5' => 5 | '6' => 6 | '7' => 7 | '8' => 8 | '9' => 9
            | 'A', 'a' => 10
            | 'B', 'b' => 11
            | 'C', 'c' => 12
            | 'D', 'd' => 13
            | 'E', 'e' => 14
            | 'F', 'f' => 15
            | _ => @fail "Expected a hex digit, found #that", 'hex digit', that

    # Consume and parse a single Unicode escape, returning a string.
    parseUnicodeEscape: ->
        if @current! == '{'
            # This is an ES6-style Unicode escape, of the form `\u{N}`

            # Eat the current character.
            @expectNext!
            @move!

            # The largest Unicode point is U+10FFFF, which has 6 hex digits. Any
            # more here is rejected, as it's pointless to try. A minimum of one
            # digit is required.
            code = @hex!

            # The first character has already been parsed, so we have to skip
            # that iteration.
            i = 1

            until @current! == '}' or i == 6, i++
                code = code .<<. 4 .|. @hex!

            @expect '}'
        else
            # Assume this is a 4-digit Unicode escape, like `\uFFFF`
            code = @hex! .<<. 12 .|. @hex! .<<. 8 .|. @hex! .<<. 4 .|. @hex!

        if code > 0x10ffff
            # Grab the hex value out of the code.
            code .= toString 16
            @fail "Unicode point too large: U+#code", void, code
        else if code > 0xffff
            # Convert `code` into a Unicode surrogate pair, and return that.
            # https://mathiasbynens.be/notes/javascript-encoding#surrogate-formulae
            code -= 0x10000
            hi = (code .>>. 10) + 0xd800
            lo = code % 0x400 + 0xdc00
            String.fromCharCode hi, lo
        else
            # It's a standard UCS-2 character. Return that.
            String.fromCharCode code

    # Parse string/atom character escapes.
    parseEscape: ->
        switch @next!
            # basic escapes
            | '0' => '\0'
            | 'b' => '\b'
            | 'f' => '\f'
            | 'n' => '\n'
            | 'r' => '\r'
            | 't' => '\t'
            | 'v' => '\v'

            # `\xNN`
            | 'x' =>
                @envs.push 'incomplete escape'
                @end String.fromCharCode @hex! .<<. 4 .|. @hex!

            # `\u{N}`, `\uNNNN`
            | 'u' =>
                @envs.push 'incomplete escape'
                @end @parseUnicodeEscape!

            | _ => that

    readStringChar: ->
        ch = @next!
        if ch == '\\' then @parseEscape! else ch

    parseString: ->
        @start 'unclosed string'
        @expect '"'

        ret = ''
        while @hasNext! and @current! != '"'
            ret += @readStringChar!

        @expect '"'

        # Cue engines to flatten string
        @end @string ret.concat!

    parseAtom: ->
        @location!


        # Protect against blank quote/quasiquote/etc. It is safe to assume here
        # that there will be a character, since @parseExpr has already asserted
        # that.
        #
        # Forms like `(')` are invalid, which this checks against.
        if /[\)"'`,]/.test @current!
            @fail "Unexpected character: #{esc @current!}", void, @current!

        ret = ''
        # Either whitespace or a metacharacter. `(a'b)` is parsed as `(a 'b)`,
        # etc.
        while @hasNext! and not /[\r\n\u2028\u2029 \t;\)"'`,]/.test @current!
            ret += @readStringChar!

        # Cue engines to flatten string
        @atom ret.concat!

    splicingType: ->
        if @lookahead '@' then 'unquote-splicing' else 'unquote'

    parseExpr: ->
        @skipWhitespace!
        @expectNext! # We're expecting at least something here.
        switch @current!
            | '('  => @parseList!
            | '\'' => @prepareQuotedLoc!; @parseQuoted 'quote'
            | '`'  => @prepareQuotedLoc!; @parseQuoted 'quasiquote'
            | ','  => @prepareQuotedLoc!; @parseQuoted @splicingType!
            | '"'  => @parseString!
            | _    => @parseAtom!

    parse: ->
        # Ignore any shebang at beginning.
        if @source.0 == '#' and @source.1 == '!'
            while @hasNext! and not @isNewline!
                @index++

            if @hasNext!
                @skipNewline!

        while @skipWhitespace!
            @parseExpr!

export parse = (source) -> new Parser source .parse!
