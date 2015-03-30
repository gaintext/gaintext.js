# GainText
#
# Martin Waitz <tali@admingilde.org>

mona = require 'mona-parser'

{NamedBlockElement, NamedSpanElement, Paragraph, globalScope} = require './block'
{collect, vskip} = require './parserutils'


anyName = mona.text mona.noneOf(': \t\n'), min: 1
exports.anyBlock = anyBlock = new NamedBlockElement anyName
exports.anySpan = anySpan = new NamedSpanElement anyName

globalScope.addSpan(anySpan)
globalScope.addBlock(anyBlock)
globalScope.addBlock(new Paragraph())

exports.document = document =
    mona.followedBy collect(globalScope.blockParser()), vskip

