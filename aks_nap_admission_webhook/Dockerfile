# ---- Build stage --------------------------------------------------------
FROM golang:1.23-alpine AS builder

WORKDIR /build

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w" -o /webhook ./cmd/webhook

# ---- Final stage --------------------------------------------------------
FROM gcr.io/distroless/static:nonroot

COPY --from=builder /webhook /webhook

USER nonroot:nonroot

ENTRYPOINT ["/webhook"]
