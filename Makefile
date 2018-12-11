.PHONY: clean
clean:
	@rm -rf public
	@mkdir public

.PHONY: build
build: clean
	@hugo

.PHONY: deploy
deploy: build
	@echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"
	@cd public/
	@git add . && git commit -m "Rebuilding site"
	@git push origin master
	@cd ..
