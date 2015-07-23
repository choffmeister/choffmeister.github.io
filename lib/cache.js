var crypto = require('crypto');

var caches = {};

var calcHash = function (str) {
  var shasum = crypto.createHash('sha1');
  shasum.update(str);
  return shasum.digest('hex');
};

var getCache = function (name) {
  if (!caches[name]) {
    caches[name] = {};
  }
  return caches[name];
};

module.exports = function (cacheName, content, fn) {
  var cache = getCache(cacheName);
  var hash = calcHash(content);

  if (cache[hash]) {
    return cache[hash];
  } else {
    var value = fn(content);
    cache[hash] = value;
    return value;
  }
};
