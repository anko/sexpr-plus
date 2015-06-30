export PATH := node_modules/.bin:$(PATH)

all: index.js

index.js: sexpr.pegjs
	pegjs < $< > $@

test: all test.ls
	lsc test.ls

clean:
	rm -f index.js

.PHONY: all test clean
