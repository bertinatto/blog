.PHONY: clean
clean:
	@rm -rf docs/
	@mkdir docs/
	@echo "blog.0xfb.me" >> docs/CNAME

.PHONY: build
build: clean
	@hugo
