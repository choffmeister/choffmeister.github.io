build:
	jekyll build

serve:
	jekyll serve --watch --drafts

deploy: build
	rsync --progress -a --delete _site/ choffmeister@choffmeister.de:/var/www/choffmeister.de

bundle:
	bundle install
