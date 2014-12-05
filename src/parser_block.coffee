
pr = require 'packrattle'

{flatseq} = require './helpers'
{line} = require './parser_line'



class IndentedState extends pr.ParserState
    constructor: (text, pos=0, end) ->
        super(text, pos, end)
        @indent = [""]
        @indentLevel = ""

    clone: ->
        rv = super()
        rv.indent = @indent
        rv.indent = []
        rv.indent[...] = @indent[...]
        rv.indentLevel = @indentLevel
        return rv

    newIndent: (level) ->
        level = @curIndent() + level
        rv = @clone()
        rv.indent.push level
        return rv

    curIndent: ->
        return @indent[@indent.length-1]

    leaveIndent: ->
        rv = @clone()
        rv.indent.pop()
        return rv

exports.IndentedState = IndentedState

endLine = pr.drop /[ \t]*\r?\n/

# just stores the indent level of the current line in state.indentLevel
exports.startLine = startLine = ->
    p = pr.regex(/[ \t]*/)
    pr.newParser "startLine",
        wrap: [p]
        matcher: (state, cont) ->
            p.parse state, (rv) ->
                if not rv.ok then return cont(rv)
                rv.state.indentLevel = rv.match[0]
                cont( new pr.Match(rv.state, null, false) )

exports.newLine = newLine = pr.chain(endLine, startLine, -> null)


# tests that this line has the same indent as in state.curIndent()
exports.sameIndent = sameIndent =
    pr.newParser "sameIndent",
        matcher: (state, cont) ->
            level = state.curIndent()
            debugger
            if state.indentLevel == level
                cont( new pr.Match(state, null, false) )
            else
                @fail(state, cont)


additionalIndent = (indent) ->
    pr.newParser "additionalIndent",
        matcher: (state, cont) ->
            level = state.curIndent()
            l = level.length
            # test for current indentation level
            if state.indentLevel.slice(0, l) != level
                return @fail(state, cont)
            # test for additional indentation
            newIndent = state.indentLevel.slice(l)
            if typeof(indent) == 'string'
                m = newIndent == indent
            else
                m = indent.exec(newIndent)
            if not m
                return @fail(state, cont)
            cont( new pr.Match(state, null, false) )


exports.indented = indented = (p, indent=/^[ \t]+$/) ->
    wrapped = pr.newParser "indented",
        wrap: [p]
        matcher: (state, cont) ->
            state = state.newIndent(state.indentLevel)
            p.parse state, (rv) ->
                debugger
                rv.state = rv.state.leaveIndent()
                cont rv
    return additionalIndent(indent).then(wrapped)


exports.oneTimeIndent = oneTimeIndent = (indent=/^[ \t]+$/) -> additionalIndent(indent).describe('oneTimeIndent')


exports.emptyLine = emptyLine = newLine.describe('emptyLine')

exports.startNewParagraph = startNewParagraph = flatseq(oneTimeIndent(/^ {1,3}/), line, newLine).describe('startNewParagraph')
exports.normalLine = normalLine = flatseq(sameIndent, line, newLine).describe('normalLine')



exports.normalBlock = normalBlock = normalLine.repeat(minCount=1)
exports.indentedParagraph = indentedParagraph = startNewParagraph.then normalBlock

exports.block = block = pr.alt(normalBlock, indentedParagraph)


blockSep = pr.drop(emptyLine.repeat(minCount=1))

exports.blocks = blocks = pr.repeatSeparated(block, blockSep, minCount=1)

exports.startDocument = startDocument = pr.chain(startLine, emptyLine.repeat(), -> null)
exports.endDocument = endDocument = emptyLine.repeat().drop()

exports.document = document = flatseq(startDocument, blocks, endDocument)

