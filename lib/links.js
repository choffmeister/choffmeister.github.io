var gutil = require('gulp-util'),
    sanitizeHtml = require('sanitize-html'),
    fs = require('fs'),
    path = require('path'),
    through = require('through2'),
    utils = require('./utils'),
    _ = require('lodash');

var resolveLink = function (link, site) {
  var match = link.match(/^([a-z]+):([^\/][^#]*)(#(.+))?$/);
  if (match) {
    var type = match[1];
    var pathOrKey = match[2];
    var anchor = match[3] || '';

    switch (type) {
      case 'pages':
      case 'posts':
        var item = _.find(site[type], function (p) {
          return p.frontMatter.key === pathOrKey;
        });
        if (item) {
          return '/' + utils.changeExtension(path.relative(path.resolve(site.target, '../src'), item.path), '.html') + anchor;
        }
        break;
      case 'images':
        var filePath = path.resolve(site.target, '../src/assets/images/' + pathOrKey);
        if (fs.existsSync(filePath) && fs.lstatSync(filePath).isFile()) {
          return '/assets/images/' + pathOrKey;
        }
        break;
      case 'mailto':
        return link;
    }

    throw new gutil.PluginError('page', { message: 'Reference to unknown link ' + link });
  } else {
    return link;
  }
};

module.exports.resolve = function (site) {
  return through.obj(
    function (file, enc, cb) {
      try {
        file.contents = new Buffer(sanitizeHtml(file.contents.toString(site.encoding), {
          allowedTags: false,
          allowedAttributes: false,
          transformTags: {
            'a': function(tagName, attribs) {
              attribs.href = resolveLink(attribs.href, site);
              return {
                tagName: 'a',
                attribs: attribs
              };
            },
            'img': function(tagName, attribs) {
              attribs.src = resolveLink(attribs.src, site);
              return {
                tagName: 'img',
                attribs: attribs
              };
            }
          }
        }), site.encoding);

        this.push(file);
        cb();
      } catch (ex) {
        cb(ex);
      }
    }
  );
};
