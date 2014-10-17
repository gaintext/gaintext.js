
{newParser, alt, drop, repeat, repeatSeparated, optional, regex, seq} = require 'packrattle'

{flatseq} = require './helpers'
{line} = require './parser_line'


startLine = /[ \t]*/
endLine = /[ \t]*\r?\n/

exports.oneLine = oneLine = flatseq(drop(startLine), line, drop(endLine))
exports.emptyLine = emptyLine = drop(seq(startLine, endLine))

exports.block = block = repeat(oneLine, minCount=1)

blockSep = drop(repeat(endLine, minCount=1))
exports.document = document = flatseq(repeat(emptyLine), repeatSeparated(block, blockSep, minCount=1), repeat(emptyLine))

