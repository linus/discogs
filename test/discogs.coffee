discogs = require '../lib/discogs'
discogs = discogs()

exports.discogs =

  master: (test) ->

    discogs.master '57279', (err, result) ->

      test.equal result.title, "The Miseducation Of Lauryn Hill"
      test.done()

  release: (test) ->

    discogs.release '227020', (err, result) ->

      test.equal result.title, "The Miseducation Of Lauryn Hill"
      test.done()

  artist: (test) ->

    discogs.artist 'lauryn hill', (err, result) ->

      test.equal result.realname, 'Lauryn Noel Hill'
      test.done()

  label: (test) ->

    discogs.label 'ruffhouse records', (err, result) ->

      test.equal result.name, 'Ruffhouse Records'
      test.done()

  search: (test) ->

    discogs.search 'miseducation', (err, result) ->

      result = result.searchresults.results[0]
      test.equal result.title, 'Lauryn Hill - The Miseducation Of Lauryn Hill'
      test.done()

  lookup: (test) ->

    discogs.lookup 'the miseducation of lauryn hill', (err, result) ->

      test.equal result.title, "The Miseducation Of Lauryn Hill"
      test.done()
