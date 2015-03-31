# GainText
#
# Martin Waitz <tali@admingilde.org>

mona = require 'mona-parser'

{NamedBlockElement, NamedSpanElement, Paragraph, globalScope} = require './block'
{collect, vskip} = require './parserutils'


anyName = mona.text mona.noneOf(': \t\n'), min: 1
exports.anyBlock = anyBlock = new NamedBlockElement anyName
exports.anySpan = anySpan = new NamedSpanElement anyName


# tags which are translated to HTML 1:1
spanTags = [
    'a', 'em', 'i', 'img', 'link', 'span'
]

for tag in spanTags
    globalScope.addSpan new NamedSpanElement tag

# tags which are translated to HTML 1:1
blockTags = [
    'code'
    'div'
    'img'
    'header'
    'pre'
    'section'
]

for tag in blockTags
    globalScope.addBlock new NamedBlockElement tag

globalScope.addBlock(new Paragraph())


exports.document = document =
    mona.followedBy collect(globalScope.blockParser()), vskip

