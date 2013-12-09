build:
	grunt prod-build

watch:
	grunt default

deploy: build
	rsync --progress -a --delete target/prod/ choffmeister@choffmeister.de:/var/www/choffmeister.de
