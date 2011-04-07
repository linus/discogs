querystring = require 'querystring'
request     = require 'request'
compress    = require 'compress'

class Discogs
    # Discogs is a simple wrapper for the [Discogs API](http://www.discogs.com/help/api)
    #
    # Initialize with a config object
    constructor: (@config) ->
      # Default format
      @config.f ?= @config.format or 'json'
      @params = querystring.stringify(config)

      @gunzip = new compress.Gunzip()
      @gunzip.init()

    # Return a proper url with api_key and format
    getUrl: (url) ->
      url = "http://www.discogs.com/#{url}" if url.substr(0, 7) isnt 'http://'
      sep = if "?" in url then "&" else "?"
    
      "#{url}#{sep}#{@params}"
    
    # Make a request
    request: (url, next) ->
      request
        uri: @getUrl(url),
        headers: {'accept-encoding': 'gzip'},
        encoding: 'binary',
        (error, res, body) =>
          if not error and 200 <= res.statusCode < 400
            if body
              body = @gunzip.inflate(body) if 'gzip' in res.headers['content-type']
              body = JSON.parse(body) if 'json' in res.headers['content-type'] or @config.f is 'json'

            next(null, body)
          else
            next(error)
    
    # Use this if you have a discogs url
    get: (url, next) ->
      @request url, next
    
    # Get a release
    release: (id, next) ->
      @request 'release/' + id,
        Discogs.responseHandler('release', next)
    
    # Get an artist
    artist: (name, next) ->
      @request 'artist/' + name,
        Discogs.responseHandler('artist', next)

    # Get a label
    label: (name, next) ->
      @request 'label/' + name,
        Discogs.responseHandler('label', next)
    
    # Search for something
    # Valid types:
    # `all`, `artists`, `labels`, `releases`, `needsvote`, `catno`, `forsale`
    search: (query, type, next) ->
      if type instanceof Function
        next = type
        type = 'all'
      @request 'search?' + querystring.stringify(type: type, q: query),
        Discogs.responseHandler('search', next)

    @responseHandler: (type, next) ->
      (err, res) ->
        return next(err, res) if err or res not instanceof Object or type not of res?.resp
        next(null, res.resp[type])

# This is the entry point.
#
# Needs a [Discogs API key](https://www.discogs.com/users/login).
#
# Takes an object as such:
#
#     config = {
#       api_key: 'string'   # Required.
#       f:       'json|xml' # Optional, defaults to 'json'. If 'xml' consumer is expected to take care of parsing
#     }
exports.discogs = (config) -> new Discogs(config)
