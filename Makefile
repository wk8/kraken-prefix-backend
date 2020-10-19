KRAKEN_APPS = \
	agent \
	build-index \
	proxy \
	tracker \
	origin

.PHONY: images
images:
	for APP in $(KRAKEN_APPS); do \
  		echo "### Building $$APP ###"; \
  		docker build . --build-arg KRAKEN_APP=$$APP -t wk88/kraken-$$APP && echo "### Successfully built $$APP" && continue; \
  		EXIT_CODE=$$?; \
  		echo "### Failed to build $$APP: exit code $$EXIT_CODE"; \
  		exit $$EXIT_CODE; \
  	done

.PHONY: publish
publish:
		for APP in $(KRAKEN_APPS); do \
      		docker push wk88/kraken-$$APP || exit $$?; \
      	done
