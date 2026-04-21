# Build stage
FROM golang:1.22-alpine AS builder

RUN apk add --no-cache git

WORKDIR /app

COPY go.mod go.sum* ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /douhua-api ./cmd/api

# Runtime stage
FROM alpine:3.20

RUN apk add --no-cache ca-certificates tzdata
ENV TZ=Asia/Shanghai

COPY --from=builder /douhua-api /usr/local/bin/douhua-api

EXPOSE 8080

ENTRYPOINT ["douhua-api"]
