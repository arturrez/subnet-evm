# syntax=docker/dockerfile:experimental
ARG AVALANCHE_VERSION=v1.7.5
# ============= Setting up base Stage ================
# Set required AVALANCHE_VERSION parameter in build image script

# ============= Compilation Stage ================
FROM golang:1.17.4-buster AS builder
#RUN apt-get update && apt-get install -y --no-install-recommends bash=5.0-4 git=1:2.20.1-2+deb10u3 make=4.2.1-1.2 gcc=4:8.3.0-1 musl-dev=1.1.21-2 ca-certificates=20200601~deb10u2 linux-headers-amd64
RUN apt-get update && apt-get install -y --no-install-recommends bash git make gcc musl-dev ca-certificates linux-headers-amd64

WORKDIR /build

# Copy avalanche dependencies first (intermediate docker image caching)
# Copy avalanchego directory if present (for manual CI case, which uses local dependency)
COPY go.mod go.sum avalanchego* ./

# Download avalanche dependencies using go mod
RUN go mod download

# Copy the code into the container
COPY . .

# Pass in SUBNET_EVM_COMMIT as an arg to allow the build script to set this externally
ARG SUBNET_EVM_COMMIT
ARG CURRENT_BRANCH

RUN export SUBNET_EVM_COMMIT=$SUBNET_EVM_COMMIT && export CURRENT_BRANCH=$CURRENT_BRANCH && ./scripts/build.sh /build/evm
LABEL org.avalabs.avalanche-version=$AVALANCHE_VERSION

# ============= Cleanup Stage ================
FROM avaplatform/avalanchego:$AVALANCHE_VERSION AS builtImage

ARG SUBNET_ID=jv9zobUSf4Tbp7h4atugmAiE6EY9PjDmLnf4NpsasBTbcd88i
ARG SUBNET_NAME=artur-vm

# Copy the evm binary into the correct location in the container
COPY --from=builder /build/evm /avalanchego/build/plugins/$SUBNET_ID
LABEL org.avalabs.subnet-id=$SUBNET_ID
LABEL org.avalabs.subnet-name=$SUBNET_NAME
