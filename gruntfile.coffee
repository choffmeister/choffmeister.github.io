module.exports = (grunt) ->
	grunt.initConfig
		less:
			prod:
				options:
					paths: ["."]
					yuicompress: false
				files: [
					src: "assets/styles/main.less"
					dest: "assets/styles/main.css"
				]

		copy:
			dev:
				files: [
					src: "bow/favicon.ico"
					dest: "target/dev/favicon.ico"
				,
					expand: true
					cwd: "bower_components/roboto-fontface/fonts"
					src: "*.*"
					dest: "assets/fonts"
				]

		exec:
			build:
				cmd: "jekyll build"
			serve:
				cmd: "jekyll serve --watch"
			deploy:
				cmd: "rsync --progress -a --delete -e \"ssh -q\" _site/ choffmeister@choffmeister.de:/var/www/choffmeister.de"

	grunt.loadNpmTasks "grunt-contrib-less"
	grunt.loadNpmTasks "grunt-contrib-copy"
	grunt.loadNpmTasks "grunt-exec"
	grunt.registerTask "default", ["less", "copy", "exec:build"]
	grunt.registerTask "serve", ["less", "copy", "exec:serve"]
	grunt.registerTask "deploy", ["default", "exec:deploy"]
