var gutil = require('gulp-util'),
    path = require('path'),
    through = require('through2');

var applyLayout = function (file, site) {
  if (file.frontMatter.layout) {
    var layout = site.layouts[file.frontMatter.layout];
    if (!layout) {
      throw new gutil.PluginError('layout', { message: 'File ' + file.path + ' refers to unknown layout ' + file.frontMatter.layout });
    }
    return new Buffer(applyLayout(layout, site).toString(site.encoding).replace('%%content%%', file.contents), site.encoding);
  } else {
    return file.contents;
  }
};

module.exports.apply = function (site) {
  return through.obj(
    function (file, enc, cb) {
      try {
        file.contents = applyLayout(file, site);
        this.push(file);
        cb();
      } catch (ex) {
        cb(ex);
      }
    }
  );
};

module.exports.list = function (site) {
  var layouts = {};
  return through.obj(
    function (file, enc, cb) {
      try {
        var name = path.basename(file.path, '.html');
        layouts[name] = file;
        this.push(file);
        cb();
      } catch (ex) {
        cb(ex);
      }
    },
    function (cb) {
      site.layouts = layouts;
      cb();
    }
  );
};
