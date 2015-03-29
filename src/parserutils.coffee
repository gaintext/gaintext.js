# GainText
#
# Martin Waitz <tali@admingilde.org>

mona = require 'mona-parser'


exports.copy = copy = (obj) ->
    newObj = new obj.constructor()
    for k, v of obj
        newObj[k] = v if obj.hasOwnProperty(k)
    return newObj


# similar to mona.collect,
# but allow to customize the reduction of parser results
exports.collect = collect = (parser, opts={}) ->
    min = opts.min || 1
    add = opts.add || (akku, v) -> akku.push(v)
    return mona.sequence (parse) ->
        akku = opts.zero || []
        while value = parse (if min>0 then parser else mona.maybe parser)
            add akku, value
            if min>0 then min--

        return mona.value akku

exports.collectText = collectText = (parser, opts={}) ->
    opts.add = (akku, v) ->
        if typeof v != 'string'
            return akku.push(v)
        i = akku.length
        if typeof akku[i-1] != 'string'
            return akku.push(v)
        akku[i-1] = akku[i-1] + v
    return collect parser, opts


newline = mona.and mona.maybe(mona.string '\r'), mona.string '\n'
exports.newline = newline = mona.label newline, "new line"

exports.hskip = hskip = mona.skip mona.oneOf ' \t'
exports.vskip = vskip = mona.skip mona.and(hskip, newline)

noWhitespace = mona.lookAhead mona.noneOf ' \t\r\n'
exports.noWhitespace = noWhitespace = mona.label noWhitespace, "no whitespace"

