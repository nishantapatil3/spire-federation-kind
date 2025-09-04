FROM golang:1.19 AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download
COPY . .

# Use Docker's built-in platform args for multi-platform builds
ARG TARGETOS
ARG TARGETARCH
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o stock-quotes-service .

# ---
FROM alpine:latest
RUN apk --no-cache add ca-certificates

WORKDIR /root/
COPY --from=builder /app/stock-quotes-service .

EXPOSE 8090

# Run the binary
ENTRYPOINT ["./stock-quotes-service"]
