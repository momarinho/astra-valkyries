# Multi-stage minimal build for Astra Valkyries telemetry & leaderboard backend
FROM golang:1.27-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY main.go models.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o server .

FROM alpine:3.21
RUN apk --no-cache add ca-certificates

WORKDIR /app
COPY --from=builder /app/server ./server

ENV PORT=8080 \
    GIN_MODE=release \
    GOMEMLIMIT=200MiB

EXPOSE 8080
CMD ["./server"]
