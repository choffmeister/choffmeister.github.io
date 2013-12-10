path = require("path")
send = require("send")
blog = require("./src/grunt-blog")
targetDev = "target/dev"
targetProd = "target/prod"

mountFolder = (connect, dir) ->
  connect.static path.resolve(dir)

module.exports = (grunt) ->
  grunt.initConfig
    requirejs:
      prod:
        options:
          baseUrl: "#{targetDev}/src"
          mainConfigFile: "#{targetDev}/src/app.js"
          name: "app"
          out: "#{targetProd}/src/app.js"
          optimize: "uglify"

    blogposts:
      dev:
        expand: true
        src: ["posts/**/*.md"]
        dest: "#{targetDev}"
        ext: ".html"
        options:
          withDrafts: true
          useGist: false

      prod:
        expand: true
        src: ["posts/**/*.md"]
        dest: "#{targetProd}"
        ext: ".html"
        options:
          withDrafts: false
          useGist: true

    blogpostsgistify:
      prod:
        expand: true
        src: ["posts/**/*.md"]
        dest: "#{targetProd}"
        ext: ".html"
        options:
          withDrafts: false
          accessToken: ""

    blogpages:
      dev:
        expand: true
        src: ["pages/**/*.jade"]
        dest: "#{targetDev}"
        ext: ".html"
        rename: (dest, src) ->
          path.join dest, (if src is "pages/index.html" then "index.html" else src)
        options:
          pretty: true
      prod:
        expand: true
        src: ["pages/**/*.jade"]
        dest: "#{targetProd}"
        ext: ".html"
        rename: (dest, src) ->
          path.join dest, (if src is "pages/index.html" then "index.html" else src)
        options:
          pretty: false

    coffee:
      dev:
        expand: true
        cwd: "src"
        src: ["**/*.coffee"]
        dest: "#{targetDev}/src"
        ext: ".js"
      test:
        expand: true
        cwd: "test"
        src: ["**/*.coffee"]
        dest: "#{targetDev}/test"
        ext: ".js"

    jade:
      dev:
        files: [
          expand: true
          src: ["resources/**/*.jade", "posts/**/*.jade"]
          dest: "#{targetDev}"
          ext: ".html"
          rename: (dest, src) ->
            path.join dest, (if src is "resources/index.html" then "index.html" else src)
        ]
        options:
          pretty: true

      prod:
        files: [
          expand: true
          src: ["resources/**/*.jade", "posts/**/*.jade"]
          dest: "#{targetProd}"
          ext: ".html"
          rename: (dest, src) ->
            path.join dest, (if src is "resources/index.html" then "index.html" else src)
        ]
        options:
          pretty: false

    less:
      dev:
        files: [
          src: "resources/styles/main.less"
          dest: "#{targetDev}/styles/main.css"
        ]
        options:
          paths: ["resources/styles"]
          yuicompress: false

      prod:
        files: [
          src: "resources/styles/main.less"
          dest: "#{targetProd}/styles/main.css"
        ]
        options:
          paths: ["resources/styles"]
          yuicompress: true

    copy:
      dev:
        files: [
          src: "resources/favicon.ico"
          dest: "#{targetDev}/favicon.ico"
        ,
          expand: true
          cwd: "resources/images"
          src: "**/*.*"
          dest: "#{targetDev}/images"
        ]

      prod:
        files: [
          expand: true
          cwd: "bower_components"
          src: "**/*"
          dest: "#{targetDev}/bower_components"
        ,
          expand: true
          cwd: "bower_components"
          src: "**/*"
          dest: "#{targetProd}/bower_components"
        ,
          src: "resources/favicon.ico"
          dest: "#{targetProd}/favicon.ico"
        ,
          src: "resources/robots.txt"
          dest: "#{targetProd}/robots.txt"
        ,
          src: "resources/.htaccess"
          dest: "#{targetProd}/.htaccess"
        ,
          expand: true
          cwd: "resources/images"
          src: "**/*.*"
          dest: "#{targetProd}/images"
        ]

    connect:
      dev:
        options:
          port: 9000
          hostname: "0.0.0.0"
          middleware: (connect) ->
            [mountFolder(connect, "#{targetDev}/")
            , mountFolder(connect, "")
            , (req, res, next) ->
              req.url = "/"
              next()
            ]

    watch:
      options:
        livereload: true

      coffeedev:
        files: ["src/**/*.coffee"]
        tasks: ["coffee:dev"]

      blog:
        files: ["posts/**/*.md", "pages/**/*.jade", "resources/views/**/*.jade"]
        tasks: ["blogposts:dev", "blogpages:dev"]

      less:
        files: ["resources/styles/**/*.less"]
        tasks: ["less:dev"]

      images:
        files: ["resources/images/**/*.*"]
        tasks: ["copy:dev"]

    clean:
      dev: ["#{targetDev}/"]
      prod: ["#{targetProd}/"]

  require("matchdep").filterDev("grunt-*").forEach grunt.loadNpmTasks
  blog(grunt)

  grunt.registerTask "dev-build", ["clean:dev", "coffee:dev", "blogposts:dev", "blogpages:dev", "less:dev", "copy:dev"]
  grunt.registerTask "prod-build", ["clean:prod", "blogpostsgistify:prod", "blogposts:prod", "blogpages:prod", "less:prod", "copy:prod", "requirejs:prod"]
  grunt.registerTask "dev-server", ["dev-build", "connect:dev"]
  grunt.registerTask "default", ["dev-server", "watch"]
