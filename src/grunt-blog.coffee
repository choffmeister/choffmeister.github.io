module.exports = (grunt) ->
  # libraries
  https = require("https")
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

  # parses all posts
  parsePosts = (files, options) ->
    _.chain(listFiles(files))
      .filter((f) -> options.withDrafts or f.name[0] != "_")
      .map((f) ->
        lines = splitLines(grunt.file.read(f.src))
        splitIndex = lines.indexOf("")
        throw new Error() if splitIndex < 0

        meta = yaml.load(lines[0..splitIndex-1].join("\n"))
        markdown = lines[splitIndex+1..].join("\n")
        markdownTokens = marked.lexer(markdown, _.extend({}, marked.defaults, options))

        _.extend({}, f, {
          meta: meta,
          title: meta.title
          publishDate: meta.publishDate
          abstract: meta.abstract
          markdown: markdown
          markdownTokens: markdownTokens
        })
      )
      .sortBy((p) -> p.publishDate)
      .reverse()
      .value()

  createOrEditGist = (gistId, files, options, callback) ->
    requestData =
      description: "Snippets for blog post at https://choffmeister.de/"
      public: true
      files: files
    requestDataString = JSON.stringify(requestData, true, 4)
    requestOptions =
      hostname: "api.github.com"
      port: 443
      headers:
        "User-Agent": "grunt-blog",
        "Content-Length": requestDataString.length
      path: if gistId? then "/gists/#{gistId}?access_token=#{options.accessToken}" else "/gists?access_token=#{options.accessToken}"
      method: if gistId? then "PATCH" else "POST"

    req = https.request requestOptions, (res) ->
      responseData = ""
      res.setEncoding("utf8");
      res.on "data", (chunk) ->
        responseData = responseData + chunk
      res.on "end", () ->
        if (res.statusCode == 200 or res.statusCode == 201)
          callback(JSON.parse(responseData), null)
        else
          callback(null, "GitHub responded with HTTP #{res.statusCode}: #{JSON.parse(responseData).message}")

    req.on "error", (err) ->
      grunt.log.error(err)
      callback(null, "GitHub request failed: #{err}")

    req.write(requestDataString)
    req.end();

  postTemplate = (rawContent) -> """
extends ../resources/views/post

block postcontent
  div.
#{_.map(splitLines(rawContent), (l) -> "    " + l).join("\n")}
"""

  grunt.registerMultiTask "blogpostsgistify", "", ->
    # merge task-specific and/or target-specific options with these defaults.
    options = @options(
      accessToken: ""
      withDrafts: false
    )

    posts = parsePosts(@files, options)
    done = @async()
    doneCount = posts.length

    _.each(posts, (p) ->
      sourceCodes = _.chain(p.markdownTokens).filter((t) -> t.type == "code").map((c) -> [c.lang, { content: c.text }]).value()

      if sourceCodes.length > 0
        createOrEditGist(p.meta.gistId, _.object(sourceCodes), options, (res, err) ->
          if not err?
            postFileWithGistId = yaml.dump(_.extend({}, p.meta, { gistId: res.id })) + "\n" + p.markdown
            grunt.file.write(p.src, postFileWithGistId)
            grunt.log.writeln("Post '#{p.src}' gistifyed (#{if p.meta.gistId? then "updated" else "created"}).");
            done() if --doneCount is 0
          else
            grunt.log.error(err)
            done(false)
        )
      else
        grunt.log.warn("Skipped gistifying since post does not contain any source code.")
        done() if --doneCount is 0
    )

  grunt.registerMultiTask "blogposts", "", ->
    # merge task-specific and/or target-specific options with these defaults.
    options = @options(
      withDrafts: false
      useGists: true
      pretty: false
    )

    posts = parsePosts(@files, options)

    done = @async()
    doneCount = posts.length

    _.each(posts, (p) ->
      try
        codes = _.filter(p.markdownTokens, (t) -> )

        if options.useGists and p.meta.gistId?
          _.chain(p.markdownTokens).filter((t) -> t.type == "code").each((c) ->
            c.type = "paragraph"
            c.text = """<script src="https://gist.github.com/choffmeister/#{p.meta.gistId}.js?file=#{c.lang}"></script>"""
          )

        rendered = marked.parser(p.markdownTokens, _.extend({}, marked.defaults, options))
        rendered2 = jade.render(postTemplate(rendered), _.extend({}, options, { filename: p.src, post: p }))

        if rendered2.length > 0
          grunt.file.write(p.dest, rendered2)
          grunt.log.writeln("File '#{p.dest}' created.");
        else
          grunt.log.warn("Destination not written because compiled files were empty.")

        done() if --doneCount is 0
      catch e
        grunt.log.error(e)
        grunt.fail.warn("Failed to compile '#{p.src}'.")
        done(false)
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
