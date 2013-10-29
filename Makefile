PATH := ./node_modules/.bin:${PATH}

build:
	npm run-script prepublish

all: clean build

dist: clean init build

clean:
	rm -rf test
	rm -rf lib/*

init:
	npm install

publish: dist
	npm publish