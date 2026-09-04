# syntax=docker/dockerfile:1.7

ARG GO_VERSION=1.24
ARG GO_ALPINE_VERSION=3.21
ARG ALPINE_VERSION=3.22
ARG SOJU_COMMIT=8bff925bd7b952babe085eedac6c5f9eb68e39c5

FROM golang:${GO_VERSION}-alpine${GO_ALPINE_VERSION} AS build

ARG SOJU_COMMIT
ARG TARGETOS
ARG TARGETARCH

RUN apk add --no-cache ca-certificates git build-base sqlite-dev

WORKDIR /src
RUN git clone https://codeberg.org/emersion/soju.git . \
    && git checkout --detach "$SOJU_COMMIT" \
    && test "$(git rev-parse HEAD)" = "$SOJU_COMMIT"

RUN CGO_ENABLED=1 GOOS="$TARGETOS" GOARCH="$TARGETARCH" \
    go build -trimpath -ldflags='-s -w' -o /out/soju ./cmd/soju \
    && CGO_ENABLED=1 GOOS="$TARGETOS" GOARCH="$TARGETARCH" \
    go build -trimpath -ldflags='-s -w' -o /out/sojudb ./cmd/sojudb

FROM alpine:${ALPINE_VERSION}

ARG SOJU_COMMIT=8bff925bd7b952babe085eedac6c5f9eb68e39c5
ARG VERSION=dev
ARG REVISION=unknown

LABEL org.opencontainers.image.title="Ploos-AS soju" \
      org.opencontainers.image.description="Reproducible non-root OCI image for the soju IRC bouncer" \
      org.opencontainers.image.source="https://github.com/Ploos-AS/soju" \
      org.opencontainers.image.url="https://github.com/Ploos-AS/soju" \
      org.opencontainers.image.version="$VERSION" \
      org.opencontainers.image.revision="$REVISION" \
      org.opencontainers.image.licenses="AGPL-3.0-only" \
      io.ploos.soju.upstream.commit="$SOJU_COMMIT"

RUN apk add --no-cache ca-certificates tzdata sqlite-libs \
    && addgroup -g 1000 -S soju \
    && adduser -u 1000 -S -D -H -h /var/lib/soju -s /sbin/nologin -G soju soju \
    && mkdir -p /etc/soju /var/lib/soju /run/soju \
    && chown -R soju:soju /var/lib/soju /run/soju \
    && chmod 0770 /run/soju

COPY --from=build /out/soju /usr/local/bin/soju
COPY --from=build /out/sojudb /usr/local/bin/sojudb
COPY config /etc/soju/config

USER 1000:1000
WORKDIR /var/lib/soju

VOLUME ["/var/lib/soju"]
EXPOSE 6667

ENTRYPOINT ["/usr/local/bin/soju"]
CMD ["-config", "/etc/soju/config"]
