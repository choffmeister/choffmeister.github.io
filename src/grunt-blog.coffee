module.exports = (grunt) ->
  # libraries
  _ = grunt.util._
  jade = require("jade")
  marked = require("marked")

  # state
  posts = null

  # render a template with jade
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

  listFiles = (files) ->
    _.chain(files)
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

  grunt.registerMultiTask "blogposts", "", ->
    # merge task-specific and/or target-specific options with these defaults.
    options = @options(
      withDrafts: false
      pretty: false
    )

    posts = _.chain(listFiles(@files))
      .filter((f) -> options.withDrafts or f.name[0] != "_")
      .map((f) ->
        content = grunt.file.read(f.src)
        _.extend({}, f, {
          title: content.match(/^title: "(.*)"$/m)[1]
          publishDate: content.match(/^publishDate: "(.*)"$/m)[1]
        })
      )
      .sortBy((p) -> p.publishDate)
      .reverse()
      .value()

    _.each(posts, (p) ->
      try
        markdown = grunt.file.read(p.src)
        rendered = marked(markdown, _.extend({}, options))

        template = """
extends ../resources/views/post

block postcontent
  div.
#{_.map(rendered.match(/^.*([\n\r]+|$)/gm), (l) -> "    " + l).join("")}
"""
        rendered2 = jade.render(template, _.extend({}, options, { filename: p.src, post: p }))

        if rendered2.length > 0
          grunt.file.write(p.dest, rendered2)
          grunt.log.writeln("File '#{p.dest}' created.");
        else
          grunt.log.warn("Destination not written because compiled files were empty.")
      catch e
        grunt.log.error(e)
        grunt.fail.warn("Failed to compile '#{p.src}'.")
    )

  grunt.registerMultiTask "blogpages", "", ->
    throw new Error("You must run task 'blogposts' before running task 'blogpages'.") if posts is null

    # merge task-specific and/or target-specific options with these defaults.
    options = @options(
      withDrafts: false
      pretty: false
    )

    pages = listFiles(@files)
    _.each(pages, (p) ->
      try
        template = grunt.file.read(p.src)
        rendered = jade.render(template, _.extend({}, options, { filename: p.src, posts: posts }))

        if rendered.length > 0
          grunt.file.write(p.dest, rendered)
          grunt.log.writeln("File '#{p.dest}' created.");
        else
          grunt.log.warn("Destination not written because compiled files were empty.")
      catch e
        grunt.log.error(e)
        grunt.fail.warn("Failed to compile '#{p.src}'.")
    )
