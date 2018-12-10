.PHONY: clean
clean:
	@rm -rf docs
	@mkdir docs

.PHONY: build
build: clean
	@hugo
