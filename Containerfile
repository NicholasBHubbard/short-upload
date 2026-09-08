FROM alpine:latest

RUN apk add --no-cache perl-mojolicious perl-io-socket-ssl \
    && addgroup -S short-upload \
    && adduser -S -G short-upload -h /short-upload short-upload

WORKDIR /short-upload

COPY --chown=short-upload:short-upload short-upload.pl .

USER short-upload:short-upload

ENV MOJO_LISTEN=http://*:8080

CMD ["perl", "short-upload.pl", "daemon", "-m", "production"]
