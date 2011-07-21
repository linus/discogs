querystring = require 'querystring'
request     = require 'request'
compress    = require 'compress'

# This is the entry point.
#
# Takes an optional format parameter, defaulting to 'json'. If 'xml' consumer is expected to take care of parsing
#
#     client = discogs("xml")
exports = module.exports = (format) ->
  gunzip = new compress.Gunzip()
  gunzip.init()

  # Return a proper url with optional format
  getUrl = (url) ->
    sep = if "?" in url then "&" else "?"
    url = "http://api.discogs.com/#{url}" if url.substr(0, 7) isnt 'http://'

    url += "#{sep}f=#{format}" if format
    url

  # Make a request
  discogsRequest = (url, next) ->
    request
      uri: getUrl url
      headers: {'accept-encoding': 'gzip'}
      encoding: 'binary'
      (error, res, body) =>
        if not error and 200 <= res.statusCode < 400
          if body
            body = gunzip.inflate(body) if 'gzip' in res.headers['content-type']
            body = JSON.parse(body) if 'json' in res.headers['content-type'] or not format

          next null, body
        else
          next error

  responseHandler = (type, next) ->
    (err, res) ->
      return next(err, res) if err or res not instanceof Object or type not of res?.resp
      next(null, res.resp[type])

  # API

  # Use this if you have a discogs url
  get: (url, next) ->
    discogsRequest url, next

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
