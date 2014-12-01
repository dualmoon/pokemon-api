priv = require './private'
mongoskin = require 'mongoskin'
request = require 'request'
expect = require('chai').expect
cheerio = require 'cheerio'
util = require 'util'

$ = ''

request.get 'http://bulbapedia.bulbagarden.net/wiki/List_of_moves', (err, res, body) ->
  $ = cheerio.load(body)

  # get all children of the table
  tableChildren = $('#mw-content-text table table').get(0).children
  # filter out all children that aren't table rows
  tableRows = tableChildren.filter (val, i, parent) ->
    val.name is 'tr'
  # axe the first row as it's the header
  tableRows.splice 0, 1
  
  moves = []
  
  for row in tableRows
    cells = row.children.filter (v,i,p) -> v.name is 'td'
    #id
    id         = cells[0].children[0].data.trim()
    name       = cells[1].children[1].children[0].data.trim()
    type       = cells[2].children[0].children[0].children[0].data.trim()
    category   = cells[3].children[0].children[0].children[0].data.trim()
    contest    = cells[4].children[0].children[0].children[0].data.trim()
    pp         = cells[5].children[0].data.trim()
    power      = cells[6].children[0].data.trim()
    accuracy   = cells[7].children[0].data.trim()
    generation = cells[8].children[0].data.trim()
    thisObj =
      "id"         : id
      "name"       : name
      "type"       : type
      "category"   : category
      "contest"    : contest
      "pp"         : pp
      "power"      : power
      "accuracy"   : accuracy
      "generation" : generation
    moves.push(thisObj)
  
  console.log moves[2]
  console.log moves[8]
