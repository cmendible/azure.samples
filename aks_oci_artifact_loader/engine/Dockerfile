FROM mcr.microsoft.com/oss/go/microsoft/golang:1.23-azurelinux3.0 AS builder
WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY *.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /engine .

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /engine /engine
EXPOSE 8080
ENTRYPOINT ["/engine"]
