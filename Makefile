.PHONY: clean
clean:
	@rm -rf docs
	@mkdir docs
	@echo "blog.bertinatto.org" >> docs/CNAME

.PHONY: build
build:
	@hugo

.PHONY: deploy
deploy: build
	@echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"
	@git add docs/ && git commit -m "Rebuilding site"
	@git push origin master
