.DEFAULT_GOAL:=help

.PHONY: build build/fedora

build: ## Build Ubuntu Droplet
	packer build build/templates/ubuntu.json

build/fedora: ## Build Fedora Droplet
	packer build build/templates/fedora.json

help: ## Show this help message
	@grep '^[a-zA-Z]' $(MAKEFILE_LIST) | sort | awk -F ':.*?## ' 'NF==2 {printf "\033[36m  %-25s\033[0m %s\n", $$1, $$2}'
