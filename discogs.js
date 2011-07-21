(function() {
  var compress, exports, querystring, request;
  var __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  querystring = require('querystring');
  request = require('request');
  compress = require('compress');
  exports = module.exports = function(format) {
    var discogsRequest, getUrl, gunzip, responseHandler;
    gunzip = new compress.Gunzip();
    gunzip.init();
    getUrl = function(url) {
      var sep;
      sep = __indexOf.call(url, "?") >= 0 ? "&" : "?";
      if (url.substr(0, 7) !== 'http://') {
        url = "http://api.discogs.com/" + url;
      }
      if (format) {
        url += "" + sep + "f=" + format;
      }
      return url;
    };
    discogsRequest = function(url, next) {
      return request({
        uri: getUrl(url),
        headers: {
          'accept-encoding': 'gzip'
        },
        encoding: 'binary'
      }, __bind(function(error, res, body) {
        var _ref;
        if (!error && (200 <= (_ref = res.statusCode) && _ref < 400)) {
          if (body) {
            if (__indexOf.call(res.headers['content-type'], 'gzip') >= 0) {
              body = gunzip.inflate(body);
            }
            if (__indexOf.call(res.headers['content-type'], 'json') >= 0 || !format) {
              body = JSON.parse(body);
            }
          }
          return next(null, body);
        } else {
          return next(error);
        }
      }, this));
    };
    responseHandler = function(type, next) {
      return function(err, res) {
        if (err || !(res instanceof Object) || !(type in (res != null ? res.resp : void 0))) {
          return next(err, res);
        }
        return next(null, res.resp[type]);
      };
    };
    return {
      get: function(url, next) {
        return discogsRequest(url, next);
      },
      release: function(id, next) {
        return discogsRequest('release/' + id, responseHandler('release', next));
      },
      artist: function(name, next) {
        return discogsRequest('artist/' + name, responseHandler('artist', next));
      },
      label: function(name, next) {
        return discogsRequest('label/' + name, responseHandler('label', next));
      },
      search: function(query, type, next) {
        if (type instanceof Function) {
          next = type;
          type = 'all';
        }
        return discogsRequest('search?' + querystring.stringify({
          type: type,
          q: query
        }), responseHandler('search', next));
      }
    };
  };
}).call(this);
