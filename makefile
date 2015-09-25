export PATH := node_modules/.bin:$(PATH)

index.js: grammar.pegjs
	pegjs < $< > $@

test: index.js test.ls
	lsc test.ls

clean:
	rm -f index.js

.PHONY: all test clean
