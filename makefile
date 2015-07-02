export PATH := node_modules/.bin:$(PATH)

all: index.js

index.js: grammar.pegjs
	pegjs < $< > $@

test: all test.ls
	lsc test.ls

test-readme: README.md all
	txm < README.md

clean:
	rm -f index.js

.PHONY: all test test-readme clean
