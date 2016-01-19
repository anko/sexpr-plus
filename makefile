export PATH := node_modules/.bin:$(PATH)

test: index.js test.ls
	lsc test.ls

.PHONY: test
