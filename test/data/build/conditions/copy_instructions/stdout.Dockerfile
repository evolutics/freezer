FROM alpine:3.10.3 AS example
ARG example
RUN if [ -n "${example}" ]; then \
    touch /root/example \
  ; fi

FROM alpine:3.10.3
ARG example
COPY --from=example /root/example* /var/empty /usr/local/bin/