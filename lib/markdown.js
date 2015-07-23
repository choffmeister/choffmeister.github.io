var marked = require('marked'),
    through = require('through2'),
    highlightjs = require('highlight.js');

var renderer = (function () {
  var r = new marked.Renderer();

  r.heading = function (text, level) {
    var renderedLevel = Math.min(level + 1, 4);
    var escapedText = text.toLowerCase().replace(/[^\w]+/g, '-');
    var anchor = '<a name="' + escapedText + '" class="anchor" href="#' + escapedText + '" aria-hidden="true"><span class="header-link"></span></a>';
    return '<h' + renderedLevel + '>' + anchor + text + '</h' + renderedLevel + '>';
  };

  r.image = function (href, title) {
    return '<img src="' + href + '" alt="' + title + '" class="img-responsive"/>';
  };

  return r;
}());

var highlight = function (code, lang) {
  if ([undefined, 'text', 'plain'].indexOf(lang) < 0) {
    return highlightjs.highlight(lang, code).value;
  }
  return code;
};

var convert = function (markdown) {
  return marked(markdown, {
    renderer: renderer,
    highlight: highlight
  });
};

module.exports.render = function () {
  return through.obj(function (file, enc, cb) {
    try {
      file.contents = new Buffer(convert(file.contents.toString('utf8')), 'utf8');
      this.push(file);
      cb();
    } catch (ex) {
      cb(ex);
    }
  });
};
