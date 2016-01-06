export PATH := node_modules/.bin:$(PATH)

index.js: parser.ls
	lsc -cp $< > $@

test:
	lsc test.ls

clean:
	rm -f index.js

.PHONY: all test clean
