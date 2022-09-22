FROM golang:1.19.1-bullseye

# copy go.mod and download dependencies
COPY /kine/go.mod /go/kine/go.mod
WORKDIR /go/kine
RUN go mod download

# copy all src and build
COPY /kine /go/kine
RUN ./scripts/build \
    && mv bin/kine /go/bin/kine

ENTRYPOINT ["/go/bin/kine"]
