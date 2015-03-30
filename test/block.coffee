# GainText
#
# Martin Waitz <tali@admingilde.org>

block = require '../src/block'
mona = require 'mona-parser'

{expect} = require 'chai'


describe 'block', ->

    describe 'Paragraph', ->

        paragraph = new block.Paragraph().parser()

        it 'parses a single line', ->
            expect(mona.parse paragraph, "Hello World.\n")
                .to.eql([['Hello World.']])

        it 'parses multiple lines', ->
            expect(mona.parse paragraph, "Hello\nWorld.\n")
                .to.eql([['Hello'], ['World.']])

        it 'skips leading blank lines', ->
            expect(mona.parse paragraph, "\nHello World.\n")
                .to.eql([['Hello World.']])

        it 'stops at blank line', ->
            expect(mona.parse paragraph,
                    "Hello World.\n\n", allowTrailing: true)
                .to.eql([['Hello World.']])

        it 'stops at white-space only line', ->
            expect(mona.parse paragraph,
                    "Hello World.\n  \n", allowTrailing: true)
                .to.eql([['Hello World.']])


    describe 'indentation', ->

        it 'rejects normal text', ->
            expect(-> mona.parse block.indentation,
                    "Hello", allowTrailing: true)
                .to.throw /expected indentation/

        it 'accepts text indented with a space', ->
            expect(mona.parse block.indentation,
                    " Hello", allowTrailing: true)
                .to.eql ' '

        it 'accepts text indented with a tab', ->
            expect(mona.parse block.indentation,
                    "\tHello", allowTrailing: true)
                .to.eql '\t'

        it 'accepts text indented with tab/space combination', ->
            expect(mona.parse block.indentation,
                    " \t Hello", allowTrailing: true)
                .to.eql ' \t '


    describe 'sameIndent', ->

        it 'accepts the empty string', ->
            expect(mona.parse block.sameIndent, '')
                .to.eql ''


    describe 'indentedBlock', ->

        text = mona.text mona.noneOf('\n'), min: 1
        line = mona.followedBy mona.and(block.sameIndent, text),
                               mona.string '\n'
        para = mona.collect line, min: 1

        it 'rejects not indented text', ->
            expect(-> mona.parse block.indentedBlock(line),
                    "Hello\n")
                .to.throw /expected indentation/

        it 'accepts indented text', ->
            expect(mona.parse block.indentedBlock(line),
                    " Hello\n")
                .to.eql 'Hello'

        it 'accepts indented paragraph', ->
            expect(mona.parse block.indentedBlock(para),
                    " Hello\n World\n")
                .to.eql ['Hello', 'World']

        it 'accepts only indented lines', ->
            expect(mona.parse block.indentedBlock(para),
                    " Hello\nWorld\n", allowTrailing: true)
                .to.eql ['Hello']


    describe 'NamedBlockElement', ->

        hello = new block.NamedBlockElement 'hello'

        it 'rejects normal text', ->
            expect(-> mona.parse hello.parser(), "hello world\n")
                .to.throw /expected/

        it 'rejects other names', ->
            expect(-> mona.parse hello.parser(), "goodbye:\n")
                .to.throw /expected/

        it 'parses an empty element', ->
            expect(mona.parse hello.parser(), "hello:\n")
                .to.eql name: 'hello', title: '', content: []

        it 'parses a simple element', ->
            expect(mona.parse hello.parser(), "hello: world\n")
                .to.eql name: 'hello', title: 'world', content: []

        it 'parses an element with simple content', ->
            expect(mona.parse hello.parser(), "hello: world\n  Here I am!\n")
                .to.eql name: 'hello', title: 'world', content: [
                    [['Here I am!']]
                ]

        it 'parses an element with multiple paragraphs', ->
            expect(mona.parse hello.parser(),
                    "hello: world\n  Here I am!\n\n  Goodbye.\n")
                .to.eql name: 'hello', title: 'world', content: [
                    [['Here I am!']], [['Goodbye.']]
                ]


    describe 'NamedSpanElement', ->

        span = new block.NamedSpanElement 'span'

        it 'rejects normal text', ->
            expect(-> mona.parse span.parser(), "text")
                .to.throw /expected/

        it 'rejects other name', ->
            expect(-> mona.parse span.parser(), "[text]")
                .to.throw /expected/

        it 'parses a simple element', ->
            expect(mona.parse span.parser(), "[span]").to.eql
                name: 'span', title: '', content: []

        it 'parses an element with title', ->
            expect(mona.parse span.parser(), "[span title]").to.eql
                name: 'span', title: 'title', content: []

        it 'parses an element with content', ->
            expect(mona.parse span.parser(), "[span: content]").to.eql
                name: 'span', title: '', content: ['content']


