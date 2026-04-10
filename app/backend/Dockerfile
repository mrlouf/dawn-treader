FROM golang:1.25-alpine AS builder

WORKDIR /app

# Copy go mod files
COPY go.mod ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Final stage - use distroless for smaller and more secure image
FROM gcr.io/distroless/static-debian12

WORKDIR /root/

# Copy the binary from builder
COPY --from=builder /app/main .

EXPOSE 8081

CMD ["./main"]
