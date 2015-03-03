# GainText
#
# Martin Waitz <tali@admingilde.org>
# ex: set sw=4 expandtab:

mona = require 'mona-parser'



copy = (obj) ->
    newObj = new obj.constructor()
    for k, v of obj
        newObj[k] = v if obj.hasOwnProperty(k)
    return newObj


indentation = mona.followedBy mona.text(mona.oneOf(' \t'), min: 1), mona.noneOf('\n')
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
        debugger
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

newLine = mona.string '\n'
exports.newLine = newLine = mona.label newLine, 'new line'

blankLine = mona.and(mona.skip(mona.oneOf ' \t'), newLine)
exports.blankLine = blankLine = mona.label blankLine, 'blank line'

textInLine = mona.sequence (parse) ->
    x = parse mona.noneOf ' \t\n'
    xs = parse mona.collect(mona.noneOf '\n')
    result = ([x].concat xs).join ""
    return mona.value result
exports.textInLine = textInLine = mona.label textInLine, 'text'
#exports.textInLine = textInLine = mona.log textInLine, 'textInLine'

textLine = mona.followedBy(mona.and(sameIndent, textInLine), newLine)
exports.textLine = textLine = mona.label textLine, 'line of text'

exports.paragraph = paragraph = mona.and mona.skip(blankLine), mona.collect(textLine, min: 1)
exports.paragraph = paragraph = mona.label paragraph, 'paragraph'
#exports.paragraph = paragraph = mona.log paragraph, 'paragraph'

exports.element = element = mona.sequence (parse) ->
    parse mona.skip blankLine
    parse sameIndent
    name = parse mona.text(mona.noneOf(': \t\n'), min: 1) # TODO only parse registered elements
    parse mona.string(':')
    parse mona.skip(mona.oneOf ' \t')
    title = parse mona.text(mona.noneOf '\n')
    parse mona.string('\n')
    parse mona.skip blankLine
    content = parse indentedContent
    return mona.value(name: name, title: title, content: content)
#exports.element = element = mona.log element,  "element"

exports.elementBlock = elementBlock = mona.and mona.skip(blankLine), mona.collect(element, min: 1)
#exports.elementBlock = elementBlock = mona.log elementBlock,  "elementBlock"

exports.block = block = mona.or elementBlock, paragraph
#exports.block = block = mona.log block,  "block"

exports.indentedContent = indentedContent = mona.or (indentedBlock mona.collect(block, min: 1)),  mona.value []

exports.document = document = mona.followedBy mona.collect(block, min: 1), mona.skip(blankLine)
