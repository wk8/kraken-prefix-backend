# TODO wkpo arm64?? see https://www.docker.com/blog/multi-arch-images/

FROM golang:1.15 AS dependencies

RUN apt-get update && apt-get install -y jq

WORKDIR /go/src/github.com/wk8/kraken-prefix-backend

COPY go.* ./
RUN go mod download

# we need source code from kraken itself (eg DB migrations) in app images
# so here we symlink kraken's repo to a static place
RUN KRAKEN_ROOT="$(go list -m -json github.com/uber/kraken | jq -r .Dir)" \
  && [ "$KRAKEN_ROOT" ] && [ "$KRAKEN_ROOT" != null ] && [ -d "$KRAKEN_ROOT" ] \
  && ln -svf "$KRAKEN_ROOT" /kraken_root

###

FROM dependencies AS builder
ARG KRAKEN_APP

# ensure the KRAKEN_APP build arg is propery populated
RUN test -n "$KRAKEN_APP"

COPY . .
RUN GOOS=linux GOARCH=amd64 go build -i -o kraken-$KRAKEN_APP -gcflags '-N -l' github.com/wk8/kraken-prefix-backend/$KRAKEN_APP

###

FROM alpine AS base

RUN apk add curl nginx

RUN mkdir -vp -m 755 /tmp/nginx /var/lib/nginx /var/log/nginx /var/run/nginx /var/run/kraken
COPY --from=dependencies /kraken_root/localdb/migrations /etc/kraken-build-index/localdb/migrations

###

FROM base

ARG KRAKEN_APP

RUN mkdir -vp -m 777 /var/log/kraken/kraken-$KRAKEN_APP /var/cache/kraken/kraken-$KRAKEN_APP

COPY --from=builder /go/src/github.com/wk8/kraken-prefix-backend/kraken-$KRAKEN_APP /usr/bin/kraken-$KRAKEN_APP

WORKDIR /etc/kraken
