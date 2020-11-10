##
# BUILD CONTAINER
##

FROM goreleaser/goreleaser:v0.146.0 as builder

WORKDIR /build

COPY . .
RUN \
apk add --no-cache make ;\
make build-linux-amd64

##
# RELEASE CONTAINER
##

FROM busybox:1.32.0-glibc

WORKDIR /

COPY --from=builder /build/dist/ocalver_linux_amd64/ocalver /usr/local/bin/

# Run as nobody user
USER 65534

ENTRYPOINT ["/usr/local/bin/ocalver"]
CMD [""]
