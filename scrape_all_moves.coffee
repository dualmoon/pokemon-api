## Requires!
request   = require 'request'
cheerio   = require 'cheerio'
fs        = require 'fs'
mongoskin = require 'mongoskin'
sys       = require 'sys'
optparse  = require 'optparse'

## Input flag options
database = file = outputChosen = filename = false
switches = [
  ['-d', '--database', 'Store scraped data directly in the database'],
  ['-f', '--file [FILENAME]', 'Store scraped data in a file as JSON strinified data']
]
parser = new optparse.OptionParser switches
parser.on 'database', ->
  database = true
  outputChosen = true
parser.on 'file', (name, value) ->
  file = true
  filename = value or 'moves.json'
  outputChosen = true
parser.parse process.argv
if not outputChosen
  console.log 'No output method chosen, dry run.'

## ~Private~ DB connect info
priv      = require './private'
# aaand build that connection like a boss
db = mongoskin.db priv.mongoString, { native_parser: true }
db.bind 'moves'

## Send out the request. Basically int main()
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
    if id is '???' then continue
    name       = $(cells).find('a').get(0).children[0].data.trim()
    type       = cells[2].children[0].children[0].children[0].data.trim()
    category   = cells[3].children[0].children[0].children[0].data.trim()
    contest    = cells[4].children[0].children[0].children[0].data.trim().replace '???', '-'
    pp         = cells[5].children[0].data.trim()
    power      = cells[6].children[0].data.trim().replace '—', '-'
    accuracy   = cells[7].children[0].data.trim().replace '—', '-'
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
    moves[id] = thisObj

  ## Some bug giving a null object at position 0
  moves = moves[1..]

  console.log "Successfully scraped #{moves.length} moves."

  if database
    db.moves.insert moves, (err, result) ->
      if err
        throw err
      else
        db.close()
        console.log 'Successfully wrote to database.\nFinishing up, one moment...'

  if file
    fs.writeFile filename, JSON.stringify(moves), (err) ->
        if err
          console.log err
        else
          console.log "Successfully wrote #{filename} to disk."
