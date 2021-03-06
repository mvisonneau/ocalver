ARG ARCH

FROM ${ARCH}/busybox:1.32-glibc

WORKDIR /

COPY ocalver /usr/local/bin/

# Run as nobody user
USER 65534

ENTRYPOINT ["/usr/local/bin/ocalver"]
CMD [""]
