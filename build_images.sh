#!/usr/bin/env bash

set -e

DEFAULT_REGISTRY=wk88

BUILDKIT_BUILDER_NAME=kraken-prefix-backend
KRAKEN_APPS='agent build-index origin proxy tracker'

usage() {
  cat << EOF
Builds all the Kraken docker images, and optionally pushes them to a registry.

Usage: $0 [--registry REGISTRY] [--push] [--buildkit] [--platforms PLATFORMS]

* REGISTRY is the registry the images belong to (defaults to $DEFAULT_REGISTRY)
* if --push is set, the images will also be pushed to the registry
* if --buildkit is set, that will be used instead of the vanilla docker builder
* using --platforms implies --buildkit, and PLATFORMS must be a comma-separated list of platforms to build for
EOF
}

main() {
  local REGISTRY=$DEFAULT_REGISTRY
  local PUSH=false
  local BUILDKIT=false
  local PLATFORMS=

  # parse args
  while [[ $# -gt 0 ]]; do
    case $1 in
      --registry)
        REGISTRY="$2" && shift 2 ;;
      --push)
        PUSH=true && shift ;;
      --buildkit)
        BUILDKIT=true && shift ;;
      --platforms)
        PLATFORMS="$2" && BUILDKIT=true && shift 2 ;;
      *)
        echo "Unknown option: $1"
        usage ;;
    esac
  done

  local VERSION
  VERSION="$(git describe --always --tags)"
  info "Building images for version $VERSION"

  local DOCKER_BUILD_COMMAND='docker '

  if $BUILDKIT; then
    ensure_use_builder
    local LOG_LINE="Using buildx builder $BUILDKIT_BUILDER_NAME"

    DOCKER_BUILD_COMMAND+='buildx build'

    if [ "$PLATFORMS" ]; then
      DOCKER_BUILD_COMMAND+=" --platform $PLATFORMS"
      LOG_LINE+=" for platforms $PLATFORMS"
    fi
    if $PUSH; then
      DOCKER_BUILD_COMMAND+=" --push"
    fi

    info "$LOG_LINE"
  else
    # vanilla build
    DOCKER_BUILD_COMMAND+='build'
  fi

  local APP BUILD_EXIT_CODE=0
  for APP in $KRAKEN_APPS; do
    info "Building $APP"

    eval "$DOCKER_BUILD_COMMAND --build-arg KRAKEN_APP=$APP -t $REGISTRY/kraken-prefix-$APP:$VERSION ." || BUILD_EXIT_CODE=$?
    [[ "$BUILD_EXIT_CODE" == 0 ]] && continue
    fatal_error "Failed to build $APP, exit code $BUILD_EXIT_CODE"
  done

  if $BUILDKIT; then
    # cleanup the builder
    docker buildx stop $BUILDKIT_BUILDER_NAME
  elif $PUSH; then
    for APP in $KRAKEN_APPS; do
      docker push "$REGISTRY/kraken-prefix-$APP:$VERSION"
    done
  fi
}

ensure_use_builder() {
  local CREATE_STDERR CREATE_EXIT_CODE=0
  CREATE_STDERR="$(docker buildx create --name $BUILDKIT_BUILDER_NAME 2>&1 > /dev/null)" || CREATE_EXIT_CODE=$?
  if [[ "$CREATE_EXIT_CODE" != 0 ]] && [[ ! "$CREATE_STDERR" =~ .*"existing instance for $BUILDKIT_BUILDER_NAME".* ]]; then
    fatal_error "Unable to create buildx builder: exit code $? and stderr: $CREATE_STDERR"
  fi

  docker buildx use $BUILDKIT_BUILDER_NAME
}

echo_stderr() {
    local COLOR
    local NO_COLOR='\033[0m'

    case "$1" in
        green)
            COLOR='\033[0;32m' ;;
        red)
            COLOR='\033[0;31m' ;;
        esac
    shift 1

    >&2 printf "${COLOR}$@\n${NO_COLOR}"
}

info() {
    echo_stderr 'green' "*** $@ ***"
}

fatal_error() {
    echo_stderr 'red' "FATAL ERROR: $@"
    exit 1
}

main "$@"
