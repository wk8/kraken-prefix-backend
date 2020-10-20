FROM golang:1.15 AS dependencies

WORKDIR /go/src/github.com/wk8/kraken-prefix-backend

COPY go.* ./
RUN go mod download

###

FROM dependencies AS builder
ARG KRAKEN_APP

# ensure that the KRAKEN_APP build arg is propery populated
RUN test -n "$KRAKEN_APP"

COPY . .
RUN go build -o kraken-$KRAKEN_APP github.com/wk8/kraken-prefix-backend/$KRAKEN_APP

###

FROM debian:10-slim AS base

RUN apt-get update && apt-get install -y curl nginx

RUN mkdir -vp -m 755 /tmp/nginx /var/lib/nginx /var/log/nginx /var/run/nginx /var/run/kraken

###

FROM base

ARG KRAKEN_APP

RUN mkdir -vp -m 777 /var/log/kraken/kraken-$KRAKEN_APP /var/cache/kraken/kraken-$KRAKEN_APP

COPY --from=builder /go/src/github.com/wk8/kraken-prefix-backend/kraken-$KRAKEN_APP /usr/bin/kraken-$KRAKEN_APP

WORKDIR /etc/kraken
