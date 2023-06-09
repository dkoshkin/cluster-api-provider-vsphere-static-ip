# Build the manager binary
FROM golang:1.19.8 as builder

# FIPS
ARG CRYPTO_LIB
ENV GOEXPERIMENT=${CRYPTO_LIB:+boringcrypto}

WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the go source
COPY . .

# Build
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GO111MODULE=on go build -ldflags "${LDFLAGS} -extldflags '-static'" -a -o manager main.go

# Use distroless as minimal base image to package the manager binary
# Refer to https://github.com/GoogleContainerTools/distroless for more details
#FROM gcr.io/distroless/static:latest
FROM alpine:3.18
RUN addgroup -S spectro
RUN adduser -S -D -h / spectro spectro
USER spectro
WORKDIR /
COPY --from=builder /workspace/manager .
ENTRYPOINT ["/manager"]
