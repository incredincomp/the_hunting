.PHONY: build

build:
	packer build build/templates/ubuntu.json

build/fedora:
	packer build build/templates/fedora.json
