# GainText
#
# Martin Waitz <tali@admingilde.org>

sut = require '../src/document'
mona = require 'mona-parser'

{expect} = require 'chai'


describe 'document', ->

    it 'parses a single element', ->
        expect(mona.parse sut.document, "div:\n").to.eql [
            name: 'div', title: '', content: []
        ]

    it 'parses several elements', ->
        expect(mona.parse sut.document, "div:\npre:\n").to.eql [
            {name: 'div', title: '', content: []}
            {name: 'pre', title: '', content: []}
        ]

    it 'parses a single paragraph', ->
        expect(mona.parse sut.document, "Hello World\n").to.eql [
            [['Hello World']]
        ]

    it 'parses a line which is similar to an element', ->
        expect(mona.parse sut.document, "Hello World:\n").to.eql [
            [['Hello World:']]
        ]

    it 'ignores leading blank lines', ->
        expect(mona.parse sut.document, "\n\nparagraph\n").to.eql [
            [['paragraph']]
        ]

    it 'ignores trailing blank lines', ->
        expect(mona.parse sut.document, "\nparagraph\n\n").to.eql [
            [['paragraph']]]

    it 'parses multiple paragraphs', ->
        text = "first\nparagraph\n\nsecond\nparagraph\n"
        expect(mona.parse sut.document, text).to.eql [
            [['first'], ['paragraph']]
            [['second'], ['paragraph']]
        ]

    it 'parses hierarchy of block elements', ->
        text =
            """
            div: a simple document
              Introduction text
              for the example

              pre:
                text

            """
        expect(mona.parse sut.document, text).to.eql [
            name: 'div', title: 'a simple document', content: [
                [['Introduction text'], ['for the example']]
                name: 'pre', title: '', content: [[['text']]]
            ]
        ]

    it 'parses embedded span element', ->
        text = "[span title: [span inner]]\n"
        expect(mona.parse sut.document, text).to.eql [
            [[
                name: 'span', title: 'title', content: [
                    name: 'span', title: 'inner', content: []
                ]
            ]]
        ]

    it 'parses embedded span element with text', ->
        text = "[span title: before[span inner]after]\n"
        expect(mona.parse sut.document, text).to.eql [
            [[
                name: 'span', title: 'title', content: [
                    "before"
                    name: 'span', title: 'inner', content: []
                    "after"
                ]
            ]]
        ]

