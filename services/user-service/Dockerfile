FROM golang:1.21-alpine3.18 AS builder

WORKDIR /app

# Install git (for go modules hosted on GitHub/Bitbucket/etc.)
RUN apk update && apk add --no-cache git

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o user-service .

FROM alpine:latest

RUN apk --no-cache add ca-certificates wget
WORKDIR /root/

COPY --from=builder /app/user-service .

EXPOSE 8001
CMD ["./user-service"]
