
{newParser, alt, drop, repeat, optional, regex, seq} = require 'packrattle'
{collapseText, flatten} = require './helpers'


identifier = /\S+/
quotedString = alt( /'[^']*'/, /"[^"]*"/ )

inlineMarkup = alt()
inlineMarkup.describer = "inline markup"

inlineMarkup =
  newParser "inline markup",
    matcher: (state, cont) ->
      aborting = false
      for p in @nested then do (p) ->
        state.addJob (=> "alt: #{state}, #{p}"), ->
          if aborting then return
          p.parse state, (rv) ->
            if rv.abort then aborting = true
            return cont(rv)

repeated = (p) -> repeat(p, minCount=1).onMatch (m) -> collapseText flatten m

anyLineChar = regex(/[^\r\n]/).onMatch flatten

# consume possile quote characters when they are adjacent to text
noMarkup = regex(/[a-zA-Z0-9]+[^\[\r\n]?/).onMatch flatten
# check for no more adjacent text
noText = drop(/[a-zA-Z0-9]/).not_().check()

textWithMarkup = repeated (alt noMarkup, inlineMarkup, anyLineChar), minCount=1

inlineAttributes = seq identifier, '=', quotedString
inlineElement = (name, attributes=inlineAttributes, contents=textWithMarkup) ->
    p = seq drop('['), drop(name), repeat( seq /\s+/, attributes ), optional( seq drop(/:\s*/), contents ), drop(/\s*/), ']'
    return p.commit().onMatch ([a, c]) -> { name: name, attributes: a, contents: flatten c }

inlineQuote = (name, opening, closing=opening, contents=textWithMarkup) ->
    p = seq drop(opening), contents, drop(closing), noText
    return p.commit().onMatch ([c]) -> { name: name, attributes: [], contents: c }

registerInlineMarkup = (element) ->
    inlineMarkup.nested.push(element)


registerInlineMarkup inlineElement('math')
registerInlineMarkup inlineElement('em')
registerInlineMarkup inlineElement('ref')
registerInlineMarkup inlineQuote('code', '`')
registerInlineMarkup inlineQuote('raw', '~')
registerInlineMarkup inlineQuote('math', '$')
registerInlineMarkup inlineQuote('em', '*')
registerInlineMarkup inlineQuote('em', '_')
registerInlineMarkup inlineQuote('reference', '[[', ']]')

exports.line = line = textWithMarkup

