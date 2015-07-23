var argv = require('yargs').argv,
    concat = require('gulp-concat'),
    connect = require('connect'),
    data = require('./lib/data'),
    eslint = require('gulp-eslint'),
    frontmatter = require('gulp-front-matter'),
    gif = require('gulp-if'),
    gulp = require('gulp'),
    gutil = require('gulp-util'),
    layout = require('./lib/layout'),
    less = require('gulp-less'),
    links = require('./lib/links'),
    livereload = require('gulp-livereload'),
    markdown = require('./lib/markdown'),
    merge = require('merge-stream'),
    minifyhtml = require('gulp-minify-html'),
    page = require('./lib/page'),
    path = require('path'),
    plumber = require('gulp-plumber'),
    rename = require('gulp-rename'),
    size = require('gulp-size'),
    uglify = require('gulp-uglify'),
    utils = require('./lib/utils');

var config = {
  dev: argv.dev,
  dist: !argv.dev,
  port: process.env.PORT || 9000
};

var site = {
  encoding: 'utf8',
  dev: config.dev,
  dist: config.dist,
  target: path.resolve(__dirname, 'target'),
  data: {},
  pages: [],
  posts: [],
  layouts: {}
};

var errorHandler = function () {
  return plumber({
    errorHandler: !config.dev ? false : function (err) {
      if (err.plugin) {
        gutil.log('Error in plugin \'' + gutil.colors.cyan(err.plugin) + '\'', gutil.colors.red(err.message));
      } else {
        gutil.log('Error', gutil.colors.red(err.message));
      }
      gutil.beep();
    }
  });
};

gulp.task('site-data', function () {
  return gulp.src(['./src/data.yml'])
    .pipe(errorHandler())
    .pipe(data.load(site));
});

gulp.task('site-layouts', function () {
  return gulp.src(['./src/layouts/*.html'])
    .pipe(errorHandler())
    .pipe(frontmatter())
    .pipe(layout.list(site));
});

gulp.task('site-pages', function () {
  return gulp.src(['./src/**/*.{html,md}'])
    .pipe(errorHandler())
    .pipe(frontmatter())
    .pipe(page.list(site));
});

gulp.task('pages', ['site-data', 'site-layouts', 'site-pages'], function () {
  var html = gulp.src(['./src/**/*.html'])
    .pipe(errorHandler())
    .pipe(frontmatter());

  var md = gulp.src(['./src/**/*.md'])
    .pipe(errorHandler())
    .pipe(frontmatter())
    .pipe(markdown.render());

  return merge(html, md)
    .pipe(errorHandler())
    .pipe(layout.apply(site))
    .pipe(page.render(site))
    .pipe(links.resolve(site))
    .pipe(rename({ extname: '.html' }))
    .pipe(gif(config.dist, minifyhtml()))
    .pipe(gulp.dest('./target'))
    .pipe(utils.reload());
});

gulp.task('assets-styles', function () {
  return gulp.src('./src/assets/styles/main.less')
    .pipe(errorHandler())
    .pipe(less({ compress: config.dist }))
    .pipe(size({ showFiles: true, gzip: config.dist }))
    .pipe(gulp.dest('./target/assets/styles'))
    .pipe(utils.reload());
});

gulp.task('assets-scripts', function () {
  return gulp.src([
      './node_modules/jquery/dist/jquery.js',
      './node_modules/bootstrap/dist/js/bootstrap.js',
      './node_modules/d3/d3.js',
      './node_modules/dimple-js/dist/dimple.latest.js',
      './src/assets/scripts/main.js'
    ])
    .pipe(concat('main.js'))
    .pipe(gif(config.dist, uglify({ preserveComments: 'some' })))
    .pipe(size({ showFiles: true, gzip: config.dist }))
    .pipe(gulp.dest('./target/assets/scripts'))
    .pipe(utils.reload());
});

gulp.task('assets-images', function () {
  return gulp.src('./src/assets/images/**/*.{png,jpg,gif}')
    .pipe(errorHandler())
    .pipe(gulp.dest('./target/assets/images'))
    .pipe(utils.reload());
});

gulp.task('assets-fonts', function () {
  return gulp.src(['./src/assets/fonts/**/*', './node_modules/font-awesome/fonts/**/*'])
    .pipe(errorHandler())
    .pipe(gulp.dest('./target/assets/fonts'))
    .pipe(utils.reload());
});

gulp.task('assets-data', function () {
  return gulp.src('./src/assets/data/**/*')
    .pipe(errorHandler())
    .pipe(gulp.dest('./target/assets/data'))
    .pipe(utils.reload());
});

gulp.task('eslint', function () {
  return gulp.src(['./gulpfile.js', './{lib,src}/**/*.js'])
    .pipe(eslint())
    .pipe(eslint.format())
    .pipe(gif(config.dist, eslint.failOnError()));
});

gulp.task('connect', ['build'], function (/*next*/) {
  var serveStatic = require('serve-static');
  connect()
    .use(serveStatic('./target'))
    .listen(config.port, function () {
      gutil.log('Listening on http://localhost:' + config.port + '/');
      //next();
    });
});

gulp.task('watch', ['build'], function () {
  livereload.listen({ auto: true });
  gulp.watch(['./src/**/*.{html,md}', './src/data.yml'], ['pages']);
  gulp.watch(['./src/assets/styles/**/*.{css,less}'], ['assets-styles']);
});

gulp.task('deploy', ['site-data', 'build'], function (cb) {
  var format = require('util').format;
  var spawn = require('child_process').spawn;
  var args = ['-avr', '--delete', './', format('%s@%s:%s/', site.data.deployment.user, site.data.deployment.host, site.data.deployment.directory)];
  var child = spawn('rsync', args, {cwd: site.target});
  child.stdout.pipe(process.stdout);
  child.stderr.pipe(process.stdout);
  child.on('close', function (code) {
    cb(code === 0 ? null : new Error('Deployment via rsync failed'));
  });
});

gulp.task('site', ['site-data', 'site-pages', 'site-layouts']);
gulp.task('assets', ['assets-styles', 'assets-scripts', 'assets-images', 'assets-fonts', 'assets-data']);

gulp.task('lint', ['eslint']);
gulp.task('test', ['lint', 'build']);
gulp.task('build', ['site', 'pages', 'assets']);

gulp.task('server', ['connect', 'watch']);
gulp.task('default', ['server']);
