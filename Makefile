PATH := ./node_modules/.bin:${PATH}

init:
	npm install --dev

test:
	nodeunit test

docs:
	docco src/*.coffee

clean-docs:
	rm -rf docs/

clean: clean-docs

dist: clean init docs test
	coffee -o lib/ -c src/
