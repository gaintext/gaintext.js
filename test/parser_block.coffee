
{expect} = require 'chai'

{oneLine, block, document} = require '../lib/gaintext/parser_block'



describe 'parser_block', ->

    describe 'oneLine', ->

        it 'rejects an empty line', ->
            expect(-> oneLine.run '\n').to.throw()

        it 'rejects a whitespace only line', ->
            expect(-> oneLine.run ' \n').to.throw()

        it 'parses simple text line', ->
            res = oneLine.run 'Hello World.\n'
            expect(res).to.eql ['Hello World.']

        it 'only matches a single line', ->
            expect(-> oneLine.run '\n\n').to.throw()


    describe 'block', ->

        it 'parses simple text line', ->
            res = block.run 'Hello World.\n'
            expect(res).to.eql [ ['Hello World.'] ]

        it 'parses several simple lines', ->
            res = block.run 'Line 1\nLine 2\n'
            expect(res).to.eql [
                    [ 'Line 1' ]
                    [ 'Line 2' ]
                ]

        it 'rejects empty lines inside block', ->
            expect(-> block.run 'Line 1\n\nLine2.\n\n').to.throw()

        it 'rejects empty lines before block', ->
            expect(-> block.run '\n\nLine.').to.throw()

        it 'rejects empty lines after block', ->
            expect(-> block.run 'Line.\n\n').to.throw()

        it 'rejects an empty block', ->
            expect(-> block.run '\n\n').to.throw()

        it 'rejects an empty line', ->
            expect(-> block.run '\n').to.throw()

        it 'rejects an empty string', ->
            expect(-> block.run '').to.throw()


    describe 'document', ->

        it 'parses simple paragraph', ->
            res = document.run 'Hello World.\n'
            expect(res).to.eql [ [ ['Hello World.'] ] ]

        it 'parses several simple paragraphs', ->
            res = document.run 'Paragraph 1.\n\nParagraph 2.\n'
            expect(res).to.eql [
                    [ ['Paragraph 1.'], ]
                    [ ['Paragraph 2.'], ]
                 ]

        it 'parses several multiline paragraphs', ->
            res = document.run 'Paragraph 1.\nLine 2.\n\nParagraph 2.\nAnother second line.\n'
            expect(res).to.eql [
                    [ ['Paragraph 1.'], ['Line 2.'] ]
                    [ ['Paragraph 2.'], ['Another second line.'] ]
                 ]

        it 'ignores empty lines around document', ->
            res = document.run '\n\nParagraph 1.\n\n\nParagraph 2.\n\n\n'
            expect(res).to.eql [
                    [ ['Paragraph 1.'], ]
                    [ ['Paragraph 2.'], ]
                 ]

