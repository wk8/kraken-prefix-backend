.DEFAULT_GOAL := all

.PHONY: all
all: test lint images

.PHONY: images
images:
	./build_images.sh

.PHONY: publish
publish:
	./build_images.sh --platforms linux/amd64,linux/arm64 --push

# the TEST_FLAGS env var can be set to eg run only specific tests
.PHONY: test
test:
	go test ./... -v -count=1 -race -cover "$$TEST_FLAGS"

.PHONY: lint
lint:
	golangci-lint run --timeout 5m
