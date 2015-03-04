#!/usr/bin/env coffee
# GainText
#
# Martin Waitz

fs = require 'fs'
mona = require 'mona-parser'

block = require './block'


parser = require('nomnom')
    .option 'output',
        abbr: 'o',
        help: 'Output file name'
    .option 'files',
        position: 0,
        list: true,
        required: true,
        help: 'file to process'


processFile = (file) ->

    text = fs.readFileSync(file).toString()
    return mona.parse block.document, text

processFiles = (files) ->

    for fname in files
        ast = processFile fname
        console.log ast


exports.run = ->

    opts = parser.parse()
    processFiles opts.files, opts.output

