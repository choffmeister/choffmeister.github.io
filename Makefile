build:
	jekyll build

serve:
	jekyll serve --watch

deploy: build
	rsync --progress -a --delete _site/ choffmeister@choffmeister.de:/var/www/choffmeister.de
