var cache = require('./cache'),
    swig = require('swig'),
    path = require('path'),
    through = require('through2'),
    _ = require('lodash');

module.exports.render = function (site) {
  return through.obj(
    function (file, enc, cb) {
      try {
        var template = cache('templates', file.contents.toString(site.encoding), function (uncachedTemplate) {
          return swig.compile(uncachedTemplate);
        });
        var rendered = template({
          site: site,
          page: file.frontMatter
        });

        file.contents = new Buffer(rendered, site.encoding);
        this.push(file);
        cb();
      } catch (ex) {
        cb(ex);
      }
    }
  );
};

module.exports.list = function (site) {
  var items = {
    pages: [],
    posts: []
  };
  return through.obj(
    function (file, enc, cb) {
      var relPath = path.relative(path.resolve(site.target, '../src'), file.path);
      var type = relPath.replace('\\', '/').match(/^([^\/]+)[\/]/);
      type = type ? type[1] : 'pages';

      if (!file.frontMatter.key) {
        var relPathNoExt = relPath.substr(0, relPath.length - path.extname(relPath).length);
        file.frontMatter.key = relPathNoExt.replace(/[^a-z0-9]/gi, '-');
      }

      if (items.hasOwnProperty(type)) {
        items[type].push(file);
      }

      this.push(file);
      cb();
    },
    function (cb) {
      items.posts = _.sortBy(items.posts, function (post) {
        return new Date(post.frontMatter.date).getTime() * -1;
      });
      _.extend(site, items);
      cb();
    }
  );
};
