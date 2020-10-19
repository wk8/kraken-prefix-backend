.DEFAULT_GOAL := all

.PHONY: all
all: test lint images

KRAKEN_APPS = \
	agent \
	build-index \
	origin \
	proxy \
	tracker

.PHONY: images
images:
	echo_stderr() { local COLOR="$$1" && shift 1 && printf "$${COLOR}*** $$@ ***\n\033[0m" 1>&2; } ; \
  	echo_info() { echo_stderr '\033[0;32m' "$$@"; } ; \
	for APP in $(KRAKEN_APPS); do \
  		echo_info "Building $$APP"; \
  		docker build . --build-arg KRAKEN_APP=$$APP -t wk88/kraken-prefix-$$APP \
  			&& echo_info "Successfully built $$APP" && continue ; \
  		EXIT_CODE=$$?; \
  		echo_stderr '\033[0;31m' "Failed to build $$APP: exit code $$EXIT_CODE"; \
  		exit $$EXIT_CODE; \
  	done

.PHONY: publish
publish:
		for APP in $(KRAKEN_APPS); do \
      		docker push wk88/kraken-prefix-$$APP || exit $$?; \
      	done

# the TEST_FLAGS env var can be set to eg run only specific tests
.PHONY: test
test:
	go test ./... -v -count=1 -race -cover "$$TEST_FLAGS"

.PHONY: lint
lint:
	golangci-lint run --timeout 5m
