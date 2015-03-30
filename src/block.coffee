# GainText
#
# Martin Waitz <tali@admingilde.org>

mona = require 'mona-parser'

{
    copy, collect, collectText,
    newline, vskip, hskip,
    noWhitespace
} = require './parserutils'


class ParserScope

    constructor: (blocks=[], spans=[]) ->
        @blockParsers = (@createParser element for element in blocks)
        @spanParsers = (@createParser element for element in spans)

    createParser: (element) ->
        p = element.parser()
        if typeof p != 'function'
            throw new Error "parser() returned #{p}"
        return p

    addBlock: (element) ->
        @blockParsers.push @createParser element

    addSpan: (element) ->
        @spanParsers.push @createParser element

    blockParserList: ->
        return @blockParsers

    spanParserList: ->
        return @spanParsers

    blockParser: (extra=[]) ->
        parsers = @blockParserList().concat(extra)
        if not parsers.length
            throw new Error "empty parser list"
        return mona.or parsers...

    spanParser: (extra=[]) ->
        debugger
        parsers = @spanParserList().concat(extra)
        if not parsers.length
            throw new Error "empty parser list"
        return mona.or parsers...


exports.globalScope = globalScope = new ParserScope()


class NestedParserScope extends ParserScope

    constructor: (@parent=globalScope, schema=[]) ->
        super(schema) # XXX

    blockParserList: ->
        if @parent
            return @blockParsers.concat @parent.blockParserList()
        else return @blockParsers

    spanParserList: ->
        if @parent
            return @spanParsers.concat @parent.spanParserList()
        else return @spanParsers



class Element

    constructor: (@schema=[]) ->

    setScope: (scope) ->
        return (parserState) ->
            newState = copy(parserState)
            newState.scope = scope
            newState.value = scope
            return newState

    newScope: ->
        return (parserState) =>
            parent = parserState.scope
            scope = new NestedParserScope(parent, @schema)
            return @setScope(scope)(parserState)

    collect: (parser) ->
        return mona.or mona.collect(parser, min: 1),
                       mona.value []

    createElement: (name, title, content) ->
        return name: name, title: title, content: content


class NamedElement extends Element

    constructor: (@nameParser, @schema=[]) ->

        if typeof @nameParser == 'string'
            @nameParser = mona.string @nameParser
        if typeof @nameParser != 'function'
            throw new Error "@nameParser is #{@nameParser}"


class NamedBlockElement extends NamedElement

    indentedContentParser: ->
        return mona.sequence (parse) =>
            parse vskip
            parse sameIndent
            name = parse @nameParser
            parse mona.string(':')
            parse hskip
            title = parse mona.text(mona.noneOf '\r\n')
            parse newline
            parse vskip
            # TBD: move the newScope into a new parser
            # which is called inside indentedBlock?
            scope = parse @newScope()
            content = parse @collect (indentedBlock scope.blockParser())
            return mona.value @createElement(name, title, content)

    underlinedTitleParser: ->
        return mona.sequence (parse) =>
            # TBD
            return mona.fail()

    parser: ->
        return mona.or(
            @indentedContentParser(),
            @underlinedTitleParser(),
        )

class SymbolicBlockElement extends Element

    constructor: (@symbol, @name) ->

    parser: ->
        return mona.sequence (parse) =>
            parse vskip
            parse sameIndent
            parse mona.string @symbol
            parse hskip
            title = parse mona.text(mona.noneOf '\r\n')
            parse newline
            parse vskip
            scope = parse @newScope()
            content = parse @collect (indentedBlock scope.blockParser())
            return mona.value @createElement(@name, title, content)


class NamedSpanElement extends NamedElement

    parser: ->
        return mona.sequence (parse) =>
            parse mona.string '['
            name = parse @nameParser
            parse hskip
            attributes = parse mona.text mona.noneOf(':]\r\n')
            # XXX: parse attributes
            if parse mona.maybe mona.string ':'
                parse hskip
                scope = parse @newScope()
                content = parse collectText scope.spanParser [mona.noneOf ']\r\n']
            else
                content = []
            parse mona.string ']'
            # TBD: parse attributes
            return mona.value @createElement(name, attributes, content)


class Paragraph extends Element

    constructor: ->
        @normalText = mona.noneOf('\r\n')

    parser: ->
        return mona.sequence (parse) =>
            parse vskip
            scope = parse @newScope()
            textInLine = collectText scope.spanParser [@normalText]
            textLine = mona.followedBy(
                mona.and(sameIndent,
                         noWhitespace,
                         textInLine),
                newline)
            return collect textLine

exports.Element = Element
exports.NamedBlockElement = NamedBlockElement
exports.NamedSpanElement = NamedSpanElement
exports.SymbolicBlockElement = SymbolicBlockElement
exports.Paragraph = Paragraph


indentation = mona.followedBy mona.text(mona.oneOf(' \t'), min: 1),
                              mona.noneOf('\n')
exports.indentation = indentation = mona.label indentation, 'indentation'

exports.getIndentLevel = getIndentLevel = (parserState) ->
    levels = parserState.indentLevels || [""]
    curLevel = levels[levels.length-1]
    newState = copy(parserState)
    newState.value = curLevel
    return newState

exports.pushIndentLevel = pushIndentLevel = (level) ->
    return (parserState) ->
        levels = copy(parserState.indentLevels || [""])
        levels.push(level)
        parserState = copy(parserState)
        parserState.indentLevels = levels
        return parserState

exports.popIndentLevel = popIndentLevel = (parserState) ->
    parserState = copy(parserState)
    parserState.indentLevels = copy(parserState.indentLevels)
    parserState.indentLevels.pop()
    return parserState

exports.indentedBlock = indentedBlock = (content, indent=indentation) ->
    return mona.sequence (parse) ->
        parse vskip
        i = parse(mona.lookAhead(indent))
        if not i? or i == ''
            # no indentation at all
            return mona.fail()

        level = parse(getIndentLevel)
        if i.substr(0, level.length) != level
            # not indented enough
            return mona.fail()

        parse(pushIndentLevel(i))
        c = parse(content)
        parse(popIndentLevel)
        return mona.value c

exports.sameIndent = sameIndent = mona.sequence (parse) ->
    level = parse(getIndentLevel)
    if level == ''
        return mona.value ''
    else
        return mona.string level

