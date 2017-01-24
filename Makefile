BRANCH		:= $(shell git rev-parse --abbrev-ref HEAD)
LDFLAGS 	:= -ldflags "-X main.Version=$(VERSION) -X main.Name=$(NAME)"

name := $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))

help: ## Shows this help text
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(name) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

test: ## Runs go test recursively
	go test ./...

dev: ## Builds a dev binary for local testing
	go build -tags dev -o $(NAME) $(LDFLAGS) cmd/$(NAME)/$(NAME).go

install: ## Installs binary in $GOPATH/bin
	go install $(LDFLAGS) cmd/$(NAME).go

build: ## Builds production binaries for darwin, freebsd, windows and solaris
	@rm -rf build/
	@gox $(LDFLAGS) \
	-osarch="darwin/amd64 darwin/386" \
	-osarch="windows/amd64 windows/386" \
	-osarch="freebsd/386 freebsd/amd64 freebsd/arm freebsd/arm64" \
	-osarch="linux/amd64 linux/386 linux/arm linux/arm64" \
	-osarch="solaris/amd64" \
	-output "build/$(NAME)_$(VERSION)_{{.OS}}_{{.Arch}}/$(NAME)" \
	./...

dist: build ## Generates distributable artifacts
	$(eval FILES := $(shell ls build))
	@rm -rf dist && mkdir dist
	@for f in $(FILES); do \
		(cd $(shell pwd)/build/$$f && tar -cvzf ../../dist/$$f.tar.gz *); \
		(cd $(shell pwd)/dist && shasum -a 512 $$f.tar.gz > $$f.sha512); \
		echo $$f; \
	done

release: dist ## Generates a release in GitHub and uploads artifacts
	@latest_tag=$$(git describe --tags `git rev-list --tags --max-count=1`); \
	comparison="$$latest_tag..HEAD"; \
	if [ -z "$$latest_tag" ]; then comparison=""; fi; \
	changelog=$$(git log $$comparison --oneline --no-merges); \
	github-release $(GHACCOUNT)/$(NAME) $(VERSION) $(BRANCH) "**Changelog**<br/>$$changelog" 'dist/*'; \
	git pull

.PHONY: test build install compile dist release

.DEFAULT_GOAL := help
