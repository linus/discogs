(function() {
  var Discogs, compress, querystring, request;
  var __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  querystring = require('querystring');
  request = require('request');
  compress = require('compress');
  Discogs = (function() {
    function Discogs(config) {
      var _base, _ref;
      this.config = config;
      (_ref = (_base = this.config).f) != null ? _ref : _base.f = this.config.format || 'json';
      this.params = querystring.stringify(config);
      this.gunzip = new compress.Gunzip();
      this.gunzip.init();
    }
    Discogs.prototype.getUrl = function(url) {
      var sep;
      if (url.substr(0, 7) !== 'http://') {
        url = "http://www.discogs.com/" + url;
      }
      sep = __indexOf.call(url, "?") >= 0 ? "&" : "?";
      return "" + url + sep + this.params;
    };
    Discogs.prototype.request = function(url, next) {
      return request({
        uri: this.getUrl(url),
        headers: {
          'accept-encoding': 'gzip'
        },
        encoding: 'binary'
      }, __bind(function(error, res, body) {
        var _ref;
        if (!error && (200 <= (_ref = res.statusCode) && _ref < 400)) {
          if (body) {
            if (__indexOf.call(res.headers['content-type'], 'gzip') >= 0) {
              body = this.gunzip.inflate(body);
            }
            if (__indexOf.call(res.headers['content-type'], 'json') >= 0 || this.config.f === 'json') {
              body = JSON.parse(body);
            }
          }
          return next(null, body);
        } else {
          return next(error);
        }
      }, this));
    };
    Discogs.prototype.get = function(url, next) {
      return this.request(url, next);
    };
    Discogs.prototype.release = function(id, next) {
      return this.request('release/' + id, Discogs.responseHandler('release', next));
    };
    Discogs.prototype.artist = function(name, next) {
      return this.request('artist/' + name, Discogs.responseHandler('artist', next));
    };
    Discogs.prototype.label = function(name, next) {
      return this.request('label/' + name, Discogs.responseHandler('label', next));
    };
    Discogs.prototype.search = function(query, type, next) {
      if (type instanceof Function) {
        next = type;
        type = 'all';
      }
      return this.request('search?' + querystring.stringify({
        type: type,
        q: query
      }), Discogs.responseHandler('search', next));
    };
    Discogs.responseHandler = function(type, next) {
      return function(err, res) {
        if (err || !(res instanceof Object) || !(type in (res != null ? res.resp : void 0))) {
          return next(err, res);
        }
        return next(null, res.resp[type]);
      };
    };
    return Discogs;
  })();
  exports.discogs = function(config) {
    return new Discogs(config);
  };
}).call(this);
