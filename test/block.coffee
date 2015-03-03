# GainText
#
# Martin Waitz <tali@admingilde.org>

block = require '../src/block'
mona = require 'mona-parser'

{expect} = require 'chai'


describe 'block', ->

    describe 'newLine', ->

        it 'parses a NL', ->
            expect(mona.parse block.newLine, "\n").to.eql('\n')

        it 'rejects other text', ->
            expect(-> mona.parse block.newLine, "boo").to.throw /expected new line/

    describe 'blankLine', ->

        it 'skips a single line feed', ->
            expect(mona.parse block.blankLine, "\n").to.eql('\n')

        it 'skips a white-space only feed', ->
            expect(mona.parse block.blankLine, " \t \n").to.eql('\n')

    describe 'textInLine', ->

        it 'parses text', ->
            expect(mona.parse block.textInLine, "Hello World.").to.eql('Hello World.')

        it 'also parses elements as text', ->
            expect(mona.parse block.textInLine, "Hello:").to.eql('Hello:')

        it 'does not include newlines', ->
            expect(-> mona.parse block.textInLine, "Hello World.\n").to.throw /expected end/

    describe 'paragraph', ->

        it 'parses a single line', ->
            expect(mona.parse block.paragraph, "Hello World.\n").to.eql(['Hello World.'])

        it 'parses multiple lines', ->
            expect(mona.parse block.paragraph, "Hello\nWorld.\n").to.eql(['Hello', 'World.'])

        it 'skips leading blank lines', ->
            expect(mona.parse block.paragraph, "\nHello World.\n").to.eql(['Hello World.'])

        it 'stops at blank line', ->
            expect(mona.parse block.paragraph, "Hello World.\n\n", allowTrailing: true).to.eql(['Hello World.'])

        it 'stops at white-space only line', ->
            expect(mona.parse block.paragraph, "Hello World.\n  \n", allowTrailing: true).to.eql(['Hello World.'])

    describe 'indentation', ->

        it 'rejects normal text', ->
            expect(-> mona.parse block.indentation, "Hello", allowTrailing: true).to.throw /expected indentation/

        it 'accepts text indented with a space', ->
            expect(mona.parse block.indentation, " Hello", allowTrailing: true).to.eql ' '

        it 'accepts text indented with a tab', ->
            expect(mona.parse block.indentation, "\tHello", allowTrailing: true).to.eql '\t'

        it 'accepts text indented with tab/space combination', ->
            expect(mona.parse block.indentation, " \t Hello", allowTrailing: true).to.eql ' \t '

    describe 'sameIndent', ->

        it 'accepts the empty string', ->
            expect(mona.parse block.sameIndent, '').to.eql ''

    describe 'indentedBlock', ->

        it 'rejects not indented text', ->
            expect(-> mona.parse block.indentedBlock(block.textLine), "Hello\n").to.throw /expected indentation/

        it 'accepts indented text', ->
            expect(mona.parse block.indentedBlock(block.textLine), " Hello\n").to.eql 'Hello'

        it 'accepts indented paragraph', ->
            expect(mona.parse block.indentedBlock(block.paragraph), " Hello\n World\n").to.eql ['Hello', 'World']

        it 'accepts only indented lines', ->
            expect(mona.parse block.indentedBlock(block.paragraph), " Hello\nWorld\n", allowTrailing: true).to.eql ['Hello']

    describe 'element', ->

        it 'rejects normal text', ->
            expect(-> mona.parse block.element, "Hello World\n").to.throw /expected/

        it 'parses an empty element', ->
            expect(mona.parse block.element, "hello:\n").to.eql name: 'hello', title: '', content: []

        it 'parses a simple element', ->
            expect(mona.parse block.element, "hello: world\n").to.eql name: 'hello', title: 'world', content: []

        it 'parses an element with simple content', ->
            expect(mona.parse block.element, "hello: world\n  Here I am!\n").to.eql name: 'hello', title: 'world', content: [['Here I am!']]

        it 'parses an element with multiple paragraphs', ->
            expect(mona.parse block.element, "hello: world\n  Here I am!\n\n  Goodbye.\n").to.eql
                name: 'hello', title: 'world', content: [['Here I am!'], ['Goodbye.']]

    describe 'elementBlock', ->

        it 'rejects normal text', ->
            expect(-> mona.parse block.elementBlock, "Hello World\n").to.throw /expected/

        it 'parses one empty element', ->
            expect(mona.parse block.elementBlock, "hello:\n").to.eql [name: 'hello', title: '', content: []]

        it 'parses multiple empty elements', ->
            expect(mona.parse block.elementBlock, "hello:\nworld:\n").to.eql [
                {name: 'hello', title: '', content: []}
                {name: 'world', title: '', content: []}
            ]

    describe 'block', ->

        it 'parses a single element', ->
            expect(mona.parse block.block, "hello:\n").to.eql [name: 'hello', title: '', content: []]

        it 'parses a several elements', ->
            expect(mona.parse block.block, "hello:\nworld:\n").to.eql [
                {name: 'hello', title: '', content: []}
                {name: 'world', title: '', content: []}
            ]

        it 'parses a single paragraph', ->
            expect(mona.parse block.block, "Hello World\n").to.eql ['Hello World']

        it 'parses a line which is similar to an element', ->
            expect(mona.parse block.block, "Hello World:\n").to.eql ['Hello World:']

    describe 'document', ->

        it 'ignores leading blank lines', ->
            expect(mona.parse block.document, "\n\nparagraph\n").to.eql [['paragraph']]

        it 'ignores trailing blank lines', ->
            expect(mona.parse block.document, "\nparagraph\n\n").to.eql [['paragraph']]

        it 'parses multiple paragraphs', ->
            expect(mona.parse block.document, "first\nparagraph\n\nsecond\nparagraph\n").to.eql [
                ['first', 'paragraph']
                ['second', 'paragraph']
            ]

        it 'parses hierarchy of elements', ->
            expect(mona.parse block.document, "example: a simple document\n  Introduction text\n  for the example\n\n  foo:\n    text\n").to.eql [
                [name: 'example', title: 'a simple document', content: [
                    ['Introduction text', 'for the example']
                    [name: 'foo', title: '', content: [['text']]]
                ]]
            ]
