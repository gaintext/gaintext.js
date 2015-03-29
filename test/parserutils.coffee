# GainText
#
# Martin Waitz <tali@admingilde.org>

{expect} = require 'chai'
mona = require 'mona-parser'

sut = require '../src/parserutils'

describe 'parserutils', ->

    describe 'collectText', ->

        parser = mona.or mona.oneOf('abc'),
                         mona.string('def'),
                         mona.bind(mona.oneOf('ABC'), (res) -> mona.value [res]),
                         mona.bind(mona.oneOf('DEF'), (res) -> mona.value res: res),
                         mona.bind(mona.oneOf('0123456789'), (res) -> mona.value parseInt(res))

        it 'collapses strings', ->
            expect(mona.parse sut.collectText(parser), "abcdef").to.eql [
                'abcdef'
            ]

        it 'does not collapse ints', ->
            expect(mona.parse sut.collectText(parser), "123").to.eql [1, 2, 3]

        it 'does not collapse arrays', ->
            expect(mona.parse sut.collectText(parser), "ABC").to.eql [['A'], ['B'], ['C']]

        it 'does not collapse objects', ->
            expect(mona.parse sut.collectText(parser), "DEF").to.eql [{res: 'D'}, {res: 'E'}, {res: 'F'}]

        it 'collapses strings inbetween other objects', ->
            expect(mona.parse sut.collectText(parser), "abC1AbcD2aBcdef3").to.eql [
                'ab', ['C'], 1, ['A'], 'bc', {res: 'D'}, 2, 'a', ['B'], 'cdef', 3
            ]

    describe 'newline', ->

        it 'parses a LF', ->
            expect(mona.parse sut.newline, "\n").to.eql '\n'

        it 'parses a CRLF', ->
            expect(mona.parse sut.newline, "\r\n").to.eql '\n'

        it 'rejects other text', ->
            expect(-> mona.parse sut.newline, "boo").to.throw /expected new line/

        it 'rejects a single CR text', ->
            expect(-> mona.parse sut.newline, "\rboo").to.throw /expected new line/


    describe 'hskip', ->

        it 'does not require whitespace', ->
            expect(mona.parse mona.and(sut.hskip, mona.string 'a'), 'a').to.eql 'a'

        it 'skips a space', ->
            expect(mona.parse mona.and(sut.hskip, mona.string 'a'), ' a').to.eql 'a'

        it 'skips a tab', ->
            expect(mona.parse mona.and(sut.hskip, mona.string 'a'), '\ta').to.eql 'a'

        it 'skips more whitespace space', ->
            expect(mona.parse mona.and(sut.hskip, mona.string 'a'), ' \t  a').to.eql 'a'

        it 'does not skip CR', ->
            expect(-> mona.parse mona.and(sut.hskip, mona.string 'a'), '\ra').to.throw /expected/

        it 'does not skip LF', ->
            expect(-> mona.parse mona.and(sut.hskip, mona.string 'a'), '\na').to.throw /expected/


    describe 'vskip', ->

        it 'does not require whitespace', ->
            expect(mona.parse mona.and(sut.vskip, mona.string 'a'), "a").to.eql 'a'

        it 'skips a single LF', ->
            expect(mona.parse mona.and(sut.vskip, mona.string 'a'), "\na").to.eql 'a'

        it 'skips a single CRLF', ->
            expect(mona.parse mona.and(sut.vskip, mona.string 'a'), "\r\na").to.eql 'a'

        it 'skips a whitespace-only line', ->
            expect(mona.parse mona.and(sut.vskip, mona.string 'a'), " \t\r\na").to.eql 'a'

        it 'skips multiple empty lines', ->
            expect(mona.parse mona.and(sut.vskip, mona.string 'a'), " \n\t\r\na").to.eql 'a'

        it 'does not skip white space indent on next line', ->
            expect(mona.parse mona.and(sut.vskip, mona.string ' a'), " \n a").to.eql ' a'


    describe 'noWhitespace', ->

        it 'rejects space', ->
            expect(-> mona.parse sut.noWhitespace, ' ').to.throw /no whitespace/

        it 'rejects tab', ->
            expect(-> mona.parse sut.noWhitespace, '\t').to.throw /no whitespace/

        it 'rejects CR', ->
            expect(-> mona.parse sut.noWhitespace, '\r').to.throw /no whitespace/

        it 'rejects LF', ->
            expect(-> mona.parse sut.noWhitespace, '\n').to.throw /no whitespace/

        it 'does not consume text', ->
            expect(mona.parse mona.and(sut.noWhitespace, mona.string 'a'), 'a').to.eql 'a'


