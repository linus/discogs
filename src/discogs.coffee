querystring = require 'querystring'
request     = require 'request'
zlib        = require 'zlib'
discogs     = require '../package.json'

# This is the entry point.
#
# Takes an optional format parameter, defaulting to 'json'. If 'xml' consumer is expected to take care of parsing
#
#     client = discogs("xml")
exports = module.exports = (format) ->
  format = null if format is 'json' # JSON is the default and the API doesn't work with f=json
  # Return a proper url with optional format
  getUrl = (url) ->

    url = "http://api.discogs.com/#{url}" if url.substr(0, 7) isnt 'http://'
    sep = if "?" in url then "&" else "?"

    url += "#{sep}f=#{format}" if format
    url

  # Make a request
  discogsRequest = (url, next) ->

    parseResponse = (err, res, body) ->

      if err then next err
      else if ~res.headers['content-type']?.indexOf('json') or not format
        try
          next null, JSON.parse body
        catch e
          next e
      else
        next null, body

    request
      uri: getUrl url
      headers:
        'accept-encoding': 'gzip'
        'user-agent': "#{discogs.name}/#{discogs.version} +#{discogs.homepage}"
      encoding: null
      (error, res, body) ->
        if not error and 200 <= res.statusCode < 400
          if ~res.headers['content-encoding']?.indexOf 'gzip'
            zlib.gunzip body, (err, body) ->
              parseResponse err, res, body
          else
            parseResponse error, res, body.toString 'utf8'
        else
          next error

  responseHandler = (type, next) -> (err, res) ->

      if err then next err
      else next null, res?.resp?[type]

  # API

  # Use this if you have a discogs url
  get: (url, next) ->
    discogsRequest url, next

  # Get a master release
  master: (id, next) ->
    discogsRequest 'master/' + id,
      responseHandler('master', next)

  # Get a release
  release: (id, next) ->
    discogsRequest 'release/' + id,
      responseHandler('release', next)

  # Get an artist
  artist: (name, next) ->
    discogsRequest 'artist/' + name,
      responseHandler('artist', next)

  # Get a label
  label: (name, next) ->
    discogsRequest 'label/' + name,
      responseHandler('label', next)

  # Search for something
  # Valid types:
  # `all`, `artists`, `labels`, `releases`, `needsvote`, `catno`, `forsale`
  search: (query, type, next) ->
    if type instanceof Function
      next = type
      type = 'all'
    discogsRequest 'search?' + querystring.stringify(type: type, q: query),
      responseHandler('search', next)

  # Do a search and try to find the master or main release in all results.
  # Uses 2 or 3 requests per lookup, to find the best result.
  lookup: (query, next) ->
    @search query, "releases", (err, res) =>
      return next err if err

      results = res?.searchresults?.results
      return next() unless results

      masters = (result for result in results when result.type is "master")
      # Did we find masters already?
      results = masters if masters.length

      matches = (result for result in results when result.title.toLowerCase() is query.toLowerCase())
      # Take only the best results
      results = matches if matches.length

      release = results[0]
      id = release.uri.split("/").pop()

      @[release.type] id, (err, res) =>
        if "master_id" of res
          # Did we find a master now?
          @master res.master_id, (err, master) =>
            if "main_release" of master
              @release master.main_release, next
            else
              next null, master
        else if "main_release" of res
          # Or maybe a main release?
          @release res.main_release, next
        else
          # This is the best we can do
          next null, res
