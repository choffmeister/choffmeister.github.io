var through = require('through2'),
    yaml = require('js-yaml');

module.exports.load = function (site) {
  var data = {};
  return through.obj(
    function (file, x, cb) {
      data = Object.assign(data, yaml.safeLoad(file.contents.toString(site.encoding)));
      this.push(file);
      cb();
    },
    function (cb) {
      site.data = data;
      cb();
    }
  );
};
