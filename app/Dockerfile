# Use golang image to build the binary
FROM golang:1.18 as builder
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Define a shipping (haha!!) container baseline image.
FROM alpine:latest
WORKDIR /root/
COPY --from=builder /app/main .
EXPOSE 80
CMD ["./main"]