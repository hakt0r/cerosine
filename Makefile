PATH := ./node_modules/.bin:${PATH}

build:
	coffee -bco lib src/*.coffee

all: clean build

dist: clean init build

clean:
	rm -rf test
	rm -rf lib/*

init:
	npm install

publish: dist
	npm publish