FROM golang:1.21-alpine AS builder
WORKDIR /app
RUN apk add --no-cache git
RUN git clone https://github.com/dkoz/palworld-palbot .
RUN go build -o palbot .

FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/palbot .
CMD ["./palbot"]
