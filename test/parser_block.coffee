
{expect} = require 'chai'

{IndentedState, normalLine, block, normalBlock, blocks, indented, startDocument, endDocument, document} = require '../src/parser_block'
{flatseq} = require '../src/helpers'


run = (p, str) ->
    state = new IndentedState(str)
    try
        p.run state, {debugGraph: true}
    catch err
        debugger
        try
            err.message = "#{err.message} @ #{err.state.loc}: #{err.state.around()} curIndent='#{err.state.curIndent()}' indentLevel='#{err.state.indentLevel}'"
        throw err

runD = (p, str) ->
    p = flatseq(startDocument, p, endDocument).onMatch( (m) -> m[1] )
    return run p, str


describe 'parser_block', ->

    describe 'normalLine', ->

        it 'rejects an empty line', ->
            expect(-> run(normalLine, '\n')).to.throw()

        it.skip 'rejects a whitespace only line', ->
            expect(-> run(normalLine, ' \n')).to.throw()

        it 'parses simple text line', ->
            res = run(normalLine, 'Hello World.\n')
            expect(res).to.eql ['Hello World.']

        it 'only matches a single line', ->
            expect(-> run(normalLine, '\n\n')).to.throw()


    describe 'block', ->

        it 'parses simple text line', ->
            res = run(block, 'Hello World.\n')
            expect(res).to.eql [ ['Hello World.'] ]

        it 'parses several simple lines', ->
            res = run(block, 'Line 1\nLine 2\n')
            expect(res).to.eql [
                [ 'Line 1' ]
                [ 'Line 2' ]
            ]

        it 'rejects empty lines inside block', ->
            expect(-> run(block, 'Line 1\n\nLine2.\n\n')).to.throw()

        it 'rejects empty lines before block', ->
            expect(-> run(block, '\n\nLine.')).to.throw()

        it 'rejects empty lines after block', ->
            expect(-> run(block, 'Line.\n\n')).to.throw()

        it 'rejects an empty block', ->
            expect(-> run(block, '\n\n')).to.throw()

        it 'rejects an empty line', ->
            expect(-> run(block, '\n')).to.throw()

        it 'rejects an empty string', ->
            expect(-> run(block, '')).to.throw()

    describe 'indented', ->

        it 'fails for not indented line', ->
            expect(-> runD(indented(normalBlock), 'no indent\n')).to.throw /Expected/

        it 'accepts indented lines', ->
            res = runD(indented(normalBlock), '    indented\n')
            expect(res).to.eql [
                [ 'indented' ]
            ]

        it 'accepts a specific indent', ->
            res = runD(indented(normalBlock, '  '), '  indented\n')
            expect(res).to.eql [
                [ 'indented' ]
            ]

        it 'rejects too little indent', ->
            expect(-> runD(indented(normalBlock, '  '), ' indented\n')).to.throw /Expected/

        it 'rejects too much indent', ->
            expect(-> runD(indented(normalBlock, '  '), '   indented\n')).to.throw /Expected/

        it 'accepts multiple lines', ->
            res = runD(indented(normalBlock), '   line1\n   line2\n')
            expect(res).to.eql [
                [ 'line1' ],
                [ 'line2' ]
            ]

        it 'accepts embedded empty lines', ->
            res = runD(indented(blocks), '   line1\n\n   line2\n')
            expect(res).to.eql [
                [ [ 'line1' ] ],
                [ [ 'line2' ] ],
            ]

        it 'accepts white-space only lines', ->
            res = runD(indented(blocks), '   line1\n  \n   line2\n')
            expect(res).to.eql [
                [ [ 'line1' ] ],
                [ [ 'line2' ] ],
            ]

        it 'stops at not indented line', ->
            res = runD(flatseq(indented(normalBlock), normalBlock), '  line1\nline2\n')
            expect(res).to.eql [
                [
                  [ 'line1' ],
                ],
                [ 'line2' ]
            ]

        it 'stops afteronly accepts correctly indented lines', ->
            res = runD(flatseq(indented(normalBlock), normalBlock), '  line1\n    line2\n  line3\n line4\n')
            expect(res).to.eql [
                [
                  [ 'line1' ],
                  [ '  line2' ],
                  [ 'line3' ],
                ],
                [ ' line4' ]
            ]

    describe 'document', ->

        it 'parses simple paragraph', ->
            res = run(document, 'Hello World.\n')
            expect(res).to.eql [ [ ['Hello World.'] ] ]

        it 'parses several simple paragraphs', ->
            res = run(document, 'Paragraph 1.\n\nParagraph 2.\n')
            expect(res).to.eql [
                [ ['Paragraph 1.'], ]
                [ ['Paragraph 2.'], ]
            ]

        it 'parses several multiline paragraphs', ->
            res = run(document, 'Paragraph 1.\nLine 2.\n\nParagraph 2.\nAnother second line.\n')
            expect(res).to.eql [
                [ ['Paragraph 1.'], ['Line 2.'] ]
                [ ['Paragraph 2.'], ['Another second line.'] ]
            ]

        it 'ignores empty lines around document', ->
            res = run(document, '\n\nParagraph 1.\n\n\nParagraph 2.\n\n\n')
            expect(res).to.eql [
                [ ['Paragraph 1.'], ]
                [ ['Paragraph 2.'], ]
            ]

