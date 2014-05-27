build: clean
	@jekyll build

serve: clean
	@jekyll serve --watch --drafts

deploy: build
	@rsync --progress -a --delete _site/ choffmeister@choffmeister.de:/var/www/de.choffmeister

bundle:
	@bundle install

clean:
	@rm -rf _site
