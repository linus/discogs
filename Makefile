PATH := ./node_modules/.bin:${PATH}

init:
	npm install --dev

docs:
	docco *.coffee

clean-docs:
	rm -rf docs/

clean: clean-docs

dist: clean init docs
	coffee -o lib/ -c src/
