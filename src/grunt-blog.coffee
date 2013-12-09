module.exports = (grunt) ->
  # libraries
  _ = grunt.util._
  yaml = require("js-yaml")
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

  # splits a string into an array of lines (the elements do not contain the line endings)
  splitLines = (str) ->
    normalized = str.replace("\r\n", "\n").replace("\r", "\n")
    _.filter(normalized.split("\n"), (l) -> l != "\n")

  # filters files to existent ones and adds some additional information
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

  postTemplate = (rawContent) -> """
extends ../resources/views/post

block postcontent
  div.
#{_.map(splitLines(rawContent), (l) -> "    " + l).join("\n")}
"""

  grunt.registerMultiTask "blogposts", "", ->
    # merge task-specific and/or target-specific options with these defaults.
    options = @options(
      withDrafts: false
      pretty: false
    )

    posts = _.chain(listFiles(@files))
      .filter((f) -> options.withDrafts or f.name[0] != "_")
      .map((f) ->
        lines = splitLines(grunt.file.read(f.src))
        splitIndex = lines.indexOf("")
        throw new Error() if splitIndex < 0

        meta = yaml.load(lines[0..splitIndex-1].join("\n"))
        markdown = lines[splitIndex+1..].join("\n")

        _.extend({}, f, {
          meta: meta,
          markdown: markdown
          title: meta.title
          publishDate: meta.publishDate
          abstract: meta.abstract
        })
      )
      .sortBy((p) -> p.publishDate)
      .reverse()
      .value()

    _.each(posts, (p) ->
      try
        rendered = marked(p.markdown, _.extend({}, options))
        rendered2 = jade.render(postTemplate(rendered), _.extend({}, options, { filename: p.src, post: p }))

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
