module.exports = (grunt) ->
  _ = grunt.util._
  jade = require('jade')

  render = (src, dest, options) ->
    try
      template = grunt.file.read(src)
      rendered = jade.render(template, options)

      if rendered.length > 0
        grunt.file.write(dest, rendered)
        grunt.log.writeln("File '#{dest}' created.");
      else
        grunt.log.warn("Destination not written because compiled files were empty.")
    catch e
      grunt.log.error(e)
      grunt.fail.warn("Jade failed to compile '#{src}'.")

  # Please see the Grunt documentation for more information regarding task
  # creation: http://gruntjs.com/creating-tasks
  grunt.registerMultiTask "blog", "", ->
    # Merge task-specific and/or target-specific options with these defaults.
    options = @options(
      withDrafts: false
      pretty: false
    )

    viewsAndPosts =

    base = _.chain(@files)
      .map((f) -> {
        src: f.src[0]
        dest: f.dest
        name: f.src[0].match(/([^\/]+)$/g)[0]
        url: f.dest.replace(/^target\/(dev|prod)/, "")
      })
      .filter((f) ->
        unless grunt.file.exists(f.src)
          grunt.log.warn "Source file \"" + f.src + "\" not found."
          false
        else
          true
      )
      .value()

    views = _.chain(base)
      .filter((f) -> not f.src.match(/^posts\//)?)
      .value()

    posts = _.chain(base)
      .filter((f) -> f.src.match(/^posts\//)? and (options.withDrafts or f.name[0] != "_"))
      .map((f) ->
        content = grunt.file.read(f.src)
        _.extend({}, f, {
          title: content.match(/^title = "(.*)"$/m)[1]
          publishDate: content.match(/^publish_date = "(.*)"$/m)[1]
        })
      )
      .sortBy((p) -> p.publishDate)
      .reverse()
      .value()

    _.each(posts, (p) -> render(p.src, p.dest, _.extend({}, options, { filename: p.src, post: p })))
    _.each(views, (v) -> render(v.src, v.dest, _.extend({}, options, { filename: v.src, posts: posts })))
