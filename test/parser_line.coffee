
{expect} = require('chai')
{parse} = require('packrattle')

{line} = require('../lib/gaintext/parser_line')


describe 'parser_line', ->

    describe 'line', ->
        it 'rejects an empty line', ->
            res = parse line, '\n'
            expect(res.ok).to.be.false

        it 'parses simple text line', ->
            res = parse line, 'Hello World.\n'
            expect(res.match).to.eql ['Hello World.']
            expect(res.ok).to.be.true

        it 'parses simple element', ->
            res = parse line, '[math]\n'
            expect(res.match).to.eql [ name: 'math', attributes: [], contents: [] ]

        it 'parses element with simple content', ->
            res = parse line, '[math:1+1]\n'
            expect(res.match).to.eql [ name: 'math', attributes: [], contents: ['1+1']]
            res = parse line, '[math: 1+1]\n'
            expect(res.match).to.eql [ name: 'math', attributes: [], contents: ['1+1']]

        it 'parses quoted element', ->
            res = parse line, '`(x) -> x+1`\n'
            expect(res.match).to.eql [ name: 'code', attributes: [], contents: ['(x) -> x+1']]

        it 'parses embedded quoted element', ->
            res = parse line, 'The function `(x) -> x+1` increments.\n'
            expect(res.match).to.eql [
                    "The function "
                    name: 'code', attributes: [], contents: ['(x) -> x+1']
                    " increments."
                ]

        it 'parses nested quoted elements', ->
            res = parse line, '*$1+1$*\n'
            expect(res.match).to.eql [
                    name: 'em'
                    attributes: []
                    contents: [
                        name: 'math'
                        attributes: []
                        contents: ["1+1"]
                    ]
                ]

        it 'parses interleaved quoted elements', ->
            res = parse line, '*$5* to 10$\n'
            expect(res.match).to.eql [
                    name: 'em', attributes: [], contents: ['$5']
                    " to 10$"
                ]

        it 'parses quotes around words', ->
            res = parse line, 'An `inline code` example.\n'
            expect(res.match).to.eql [
                    'An '
                    name: 'code', attributes: [], contents: ['inline code']
                    ' example.'
                ]

        it 'parses freestanding quotes', ->
            res = parse line, 'Freestanding ~ quoted text ~ in one line.\n'
            expect(res.match).to.eql [
                    'Freestanding '
                    name: 'raw', attributes: [], contents: [' quoted text ']
                    ' in one line.'
                ]

        it 'parses adjacent quote chars as text (after text)', ->
            res = parse line, 'It costs between 5$ and 10$.\n'
            expect(res.match).to.eql ['It costs between 5$ and 10$.']

        it 'parses adjacent quote chars as text (before text)', ->
            res = parse line, 'It costs between $5 and $10.\n'
            expect(res.match).to.eql ['It costs between $5 and $10.']

        it 'parses adjacent elements', ->
            res = parse line, 'within[em: one]word.\n'
            expect(res.match).to.eql [
                    "within"
                    name: 'em', attributes: [], contents: ['one']
                    "word."
                ]

