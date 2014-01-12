all: run

bundle:
	bundle install

run:
	jekyll serve --watch
