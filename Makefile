NAME             := ocalver
FILES            := $(shell git ls-files */*.go)
REPOSITORY       := mvisonneau/$(NAME)
EDGE_RELEASE_TAG := $(shell git tag | grep -E "^.*-")
.DEFAULT_GOAL    := help

export GO111MODULE=on

.PHONY: setup
setup: ## Install required libraries/tools for build tasks
	@command -v cover 2>&1 >/dev/null       || GO111MODULE=off go get -u -v golang.org/x/tools/cmd/cover
	@command -v goimports 2>&1 >/dev/null   || GO111MODULE=off go get -u -v golang.org/x/tools/cmd/goimports
	@command -v gosec 2>&1 >/dev/null       || GO111MODULE=off go get -u -v github.com/securego/gosec/cmd/gosec
	@command -v goveralls 2>&1 >/dev/null   || GO111MODULE=off go get -u -v github.com/mattn/goveralls
	@command -v ineffassign 2>&1 >/dev/null || GO111MODULE=off go get -u -v github.com/gordonklaus/ineffassign
	@command -v misspell 2>&1 >/dev/null    || GO111MODULE=off go get -u -v github.com/client9/misspell/cmd/misspell
	@command -v revive 2>&1 >/dev/null      || GO111MODULE=off go get -u -v github.com/mgechev/revive
	@command -v jq 2>&1 >/dev/null          || (echo "jq is not installed"; exit 1)
	@command -v curl 2>&1 >/dev/null        || (echo "curl is not installed"; exit 1)

.PHONY: fmt
fmt: setup ## Format source code
	goimports -w $(FILES)

.PHONY: lint
lint: revive vet goimports ineffassign misspell gosec ## Run all lint related tests against the codebase

.PHONY: revive
revive: setup ## Test code syntax with revive
	revive -config .revive.toml $(FILES)

.PHONY: vet
vet: ## Test code syntax with go vet
	go vet ./...

.PHONY: goimports
goimports: setup ## Test code syntax with goimports
	goimports -d $(FILES) > goimports.out
	@if [ -s goimports.out ]; then cat goimports.out; rm goimports.out; exit 1; else rm goimports.out; fi

.PHONY: ineffassign
ineffassign: setup ## Test code syntax for ineffassign
	ineffassign ./...

.PHONY: misspell
misspell: setup ## Test code with misspell
	misspell -error $(FILES)

.PHONY: gosec
gosec: setup ## Test code for security vulnerabilities
	gosec ./...

.PHONY: test
test: ## Run the tests against the codebase
	go test -v -count=1 -race ./...

.PHONY: install
install: ## Build and install locally the binary (dev purpose)
	go install ./cmd/$(NAME)

.PHONY: build-local
build-local: ## Build the binaries using local GOOS
	go build ./cmd/$(NAME)

.PHONY: build
build: ## Build the binaries
	goreleaser release --snapshot --skip-publish --rm-dist

.PHONY: release
release: ## Build & release the binaries (stable)
	goreleaser release --rm-dist
	find dist -type f -name "*.snap" -exec snapcraft upload --release stable '{}' \;

.PHONY: prerelease
prerelease: setup ## Build & prerelease the binaries on Snapcraft & Docker (edge)
	@echo "deleting edge release: $$asset_url"
	curl -sLX DELETE -u max:$(GITHUB_TOKEN) "$(shell curl -sL -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/$(REPOSITORY)/releases/tags/$(EDGE_RELEASE_TAG) | jq ".url")" || true

	@echo "deleting edge tags: $(EDGE_RELEASE_TAG)"
	git tag -d $(EDGE_RELEASE_TAG)
	curl -sLX DELETE -u max:$(GITHUB_TOKEN) "https://api.github.com/repos/$(REPOSITORY)/git/refs/tags/$(EDGE_RELEASE_TAG)" || true

	git tag $(shell git describe --abbrev=7 --tags --exclude=$(EDGE_RELEASE_TAG))
	goreleaser release \
		--rm-dist \
		--skip-validate \
		-f .goreleaser.pre.yml

	find dist -type f -name "*.snap" -exec snapcraft upload --release edge '{}' \;

.PHONY: prerelease-github
prerelease-github: setup ## Build & prerelease the binaries on GitHub (edge)
	git tag -f $(EDGE_RELEASE_TAG)
	@for asset_url in $(shell curl -sL -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/mvisonneau/ocalver/releases/tags/$(EDGE_RELEASE_TAG) | jq ".url"); do \
		echo "deleting already existent release: $$asset_url"; \
		curl -sLX DELETE -u max:$(GITHUB_TOKEN) "$$asset_url"; \
	done

	goreleaser release \
		--rm-dist \
		--skip-validate \
		-f .goreleaser.pre.github.yml

.PHONY: clean
clean: ## Remove binary if it exists
	rm -f $(NAME)

.PHONY: coverage
coverage: ## Generates coverage report
	rm -rf *.out
	go test -count=1 -race -v ./... -coverpkg=./... -coverprofile=coverage.out

.PHONY: coverage-html
coverage-html: ## Generates coverage report and displays it in the browser
	go tool cover -html=coverage.out

.PHONY: dev-env
dev-env: ## Build a local development environment using Docker
	@docker run -it --rm \
		-v $(shell pwd):/go/src/github.com/mvisonneau/$(NAME) \
		-w /go/src/github.com/mvisonneau/$(NAME) \
		golang:1.16 \
		/bin/bash -c 'make setup; make install; bash'

.PHONY: is-git-dirty
is-git-dirty: ## Tests if git is in a dirty state
	@git status --porcelain
	@test $(shell git status --porcelain | grep -c .) -eq 0

.PHONY: all
all: lint test build coverage ## Test, builds and ship package for all supported platforms

.PHONY: help
help: ## Displays this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
