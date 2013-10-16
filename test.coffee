#!/usr/bin/env coffee

path = require 'path'
fs = require 'fs'
sys = require 'os'
{Parser, tree} = require 'less'
walk = require 'walk'
mkdirp = require 'mkdirp'
StylusVisitor = require './to-stylus-visitor'

usage = '''
Usage: $0 -r -h -f <lessfile> [destination]
'''

options = require('optimist')
options.usage(usage)
  .alias('f', 'follow-links')
  .boolean('f')
  .boolean('h')
  .boolean('r')
  .describe('r', 'recursive')
  .describe('f', 'follow link files')
  .describe('h', 'show help')
  .check (argv) ->
    if argv._.length < 2
      throw 'Not enough parameters'


argv = options.argv

if argv.h
  options.showHelp()

source = argv._[0]
dest = argv._[1]
if !fs.existsSync source
  console.log "File #{source} does not exists."
  options.showHelp()

source = argv._[0]
dest = argv._[1]

fs.stat source, (err, stats) ->
  if stats.isFile()
    processFile source, dest, (err) ->
      if err then console.error err

  else if stats.isDirectory()
    walker = walk.walk source, {followLinks: argv.f}

    walker.on 'file', (root, fileStats, next) ->
      relativePath = path.relative source, root
      destFilename = path.basename fileStats.name, '.less'
      destFilename += '.styl'
      destDir = "#{dest}/#{relativePath}"
      srcFile =  "#{source}/#{relativePath}/#{fileStats.name}"
      destFile = "#{destDir}/#{destFilename}"
      processFile srcFile, destFile, (err) ->
        if err then console.error err
        next()
  else
    options.showHelp()


processFile = (src, dest, cb) ->
  parser = new Parser {filename: src}

  mkdirp path.dirname(dest), (err) ->
    if err then return cb err

    fs.readFile src, {encoding: 'utf8'}, (err, data) ->
      if err then return cb err

      parser.parse data, (err, node) ->
        if err then return cb err

        stylusRender = new StylusVisitor tree
        str = stylusRender.run node
        #console.log '-------------------'
        #console.log str

