FROM alpine:3.8

ENV PROTOC_VER=3.8.0
RUN apk --update add curl libc6-compat && rm -rf /var/cache/apk/*
RUN curl -OL https://github.com/google/protobuf/releases/download/v$PROTOC_VER/protoc-$PROTOC_VER-linux-x86_64.zip
RUN unzip -o protoc-$PROTOC_VER-linux-x86_64.zip -d /usr/local
RUN rm -f protoc-$PROTOC_VER-linux-x86_64.zip

