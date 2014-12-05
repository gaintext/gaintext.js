
{expect} = require 'chai'

{line} = require '../src/parser_line'


describe 'parser_line', ->

    describe 'line', ->

        it 'rejects an empty line', ->
            expect(-> line.run '').to.throw /Expected/

        it 'rejects LF', ->
            expect(-> line.run 'Text.\n').to.throw /Expected/

        it 'parses simple text line', ->
            res = line.run 'Hello World.'
            expect(res).to.eql ['Hello World.']

        it 'parses long text line', ->
            long = "A bc def ghij klmno pqrstu vwxyzäö ü1234567 890 "
            long = long + long + long + long
            res = line.run long
            expect(res).to.eql [long]

        it 'parses simple element', ->
            res = line.run '[math]'
            expect(res).to.eql [ name: 'math', attributes: [], contents: [] ]

        it 'parses element with simple content', ->
            res = line.run '[math:1+1]'
            expect(res).to.eql [ name: 'math', attributes: [], contents: ['1+1']]
            res = line.run '[math: 1+1]'
            expect(res).to.eql [ name: 'math', attributes: [], contents: ['1+1']]

        it 'parses quoted element', ->
            res = line.run '`(x) -> x+1`'
            expect(res).to.eql [ name: 'code', attributes: [], contents: ['(x) -> x+1']]

        it 'parses embedded quoted element', ->
            res = line.run 'The function `(x) -> x+1` increments.'
            expect(res).to.eql [
                    "The function "
                    name: 'code', attributes: [], contents: ['(x) -> x+1']
                    " increments."
                ]

        it 'parses nested quoted elements', ->
            res = line.run '*$1+1$*'
            expect(res).to.eql [
                    name: 'em'
                    attributes: []
                    contents: [
                        name: 'math'
                        attributes: []
                        contents: ["1+1"]
                    ]
                ]

        it 'parses interleaved quoted elements', ->
            res = line.run '*$5* to 10$'
            expect(res).to.eql [
                    name: 'em', attributes: [], contents: ['$5']
                    " to 10$"
                ]

        it 'parses quotes around words', ->
            res = line.run 'An `inline code` example.'
            expect(res).to.eql [
                    'An '
                    name: 'code', attributes: [], contents: ['inline code']
                    ' example.'
                ]

        it 'parses freestanding quotes', ->
            res = line.run 'Freestanding ~ quoted text ~ in one line.'
            expect(res).to.eql [
                    'Freestanding '
                    name: 'raw', attributes: [], contents: [' quoted text ']
                    ' in one line.'
                ]

        it 'parses adjacent quote chars as text (after text)', ->
            res = line.run 'It costs between 5$ and 10$.'
            expect(res).to.eql ['It costs between 5$ and 10$.']

        it 'parses adjacent quote chars as text (before text)', ->
            res = line.run 'It costs between $5 and $10.'
            expect(res).to.eql ['It costs between $5 and $10.']

        it 'parses adjacent elements', ->
            res = line.run 'within[em: one]word.'
            expect(res).to.eql [
                    "within"
                    name: 'em', attributes: [], contents: ['one']
                    "word."
                ]

