FROM golang:1.25-alpine AS builder

WORKDIR /build

# Копируем go.mod и go.sum для кэширования зависимостей
COPY go.mod go.sum ./
RUN go mod download

# Копируем исходники
COPY . .

# Собираем Caddy
RUN CGO_ENABLED=0 go build -o caddy -ldflags "-s -w" ./cmd/caddy

# Финальный образ
FROM alpine:latest

RUN apk --no-cache add ca-certificates

COPY --from=builder /build/caddy /usr/bin/caddy

EXPOSE 80 443 2019

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
