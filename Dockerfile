FROM golang:buster

RUN mkdir -p /usr/local/include
RUN mkdir -p /usr/local/bin
RUN mkdir -p /go/bin

ENV GOPATH=/go
ENV GO111MODULE=auto

ARG PROTOC_VERSION=3.19.4
ARG GEN_GO_GRPC_VERSION=1.0.0
ARG GEN_GRPC_GATEWAY_VERSION=2.7.3
ARG GEN_GRPC_GATEWAY_LEGACY=1.16.0
ARG GEN_GO_VERSION=1.27.1

WORKDIR /go

RUN apt-get clean
RUN apt-get update 
RUN apt-get install -y git make curl zip

RUN curl -OL https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip
RUN unzip protoc-${PROTOC_VERSION}-linux-x86_64.zip -d protoc3
RUN mv protoc3/bin/* /usr/local/bin/
RUN mv protoc3/include/* /usr/local/include/
RUN chmod +x /usr/local/bin/protoc

RUN set -e && \
    go install google.golang.org/protobuf/cmd/protoc-gen-go@v${GEN_GO_VERSION}

RUN set -e && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v${GEN_GO_GRPC_VERSION}

RUN set -e && \
    go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@v${GEN_GRPC_GATEWAY_VERSION}

ADD ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
