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
  filename = value or 'pokemon.json'
  outputChosen = true
parser.parse process.argv
if not outputChosen
  console.log 'No output method chosen, dry run.'

## ~Private~ DB connect info
priv      = require './private'
# aaand build that connection like a boss
db = mongoskin.db priv.mongoString, { native_parser: true }
db.bind 'pokemon'

request.get 'http://bulbapedia.bulbagarden.net/wiki/Ndex', (err, res, body) ->
  $ = cheerio.load(body)
  
  # get all the tables
  rows = $('table').find('tr[style="background:#FFFFFF;"]')

  pokemon = []

  for row in rows
    obj =
      id: parseInt $(row).find('td').get(1).children[0].data.trim().replace('#','')
      bpUrl: $($(row).find('td').get(3)).find('a').get(0).attribs.href
      name: $($(row).find('td').get(3)).find('a').get(0).children[0].data.trim()
      sprite: $($(row).find('td').get(2)).find('img').get(0).attribs.src
      type: []
    obj.type.push $($(row).find('td').get(4)).find('span').get(0).children[0].data.trim()
    if $($(row).find('td').get(5)).find('span').length is 1
      obj.type.push $($(row).find('td').get(5)).find('span').get(0).children[0].data.trim()
    pokemon.push obj

  console.log "Successfully scraped #{pokemon.length} Pokemon."

  if database
    db.pokemon.insert pokemon, (err, result) ->
      if err
        throw err
      else
        db.close()
        console.log 'Successfully wrote to database.\nFinishing up, one moment...'

  if file
    fs.writeFile filename, JSON.stringify(pokemon), (err) ->
        if err
          console.log err
        else
          console.log "Successfully wrote #{filename} to disk."

  ###
  0 - local dex id
  1 - national dex id
  2 - sprite
  3 - name
  4 - type
  5 - second type, if exists
  ###
