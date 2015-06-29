export PATH := node_modules/.bin:$(PATH)

all: index.js

index.js: sexpr.pegjs
	pegjs < $< > $@

test: all test.js
	node test.js

clean:
	rm -f index.js

.PHONY: all test clean
