# Stage 1: Build Go Application
FROM golang:1.24 AS builder

WORKDIR /app

# Copy and install dependencies
COPY go.mod go.sum ./
RUN go mod tidy

# Copy the project source code
COPY . .

# Build the Go application
RUN go build -o app

# Stage 2: Use prebuilt LaTeX image and add compiled binary
FROM prybruhta/my-latex-base AS runtime

WORKDIR /app

# Copy the compiled Go binary from the builder
COPY --from=builder /app/app .

# Expose the port
EXPOSE 8080

# Run the server
CMD ["./app"]
