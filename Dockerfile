# Stage 1: Build Go Application
FROM golang:1.24 AS builder

WORKDIR /app

# Copy and install dependencies
COPY go.mod go.sum ./
RUN go mod tidy && go mod download

# Copy the project source code
COPY . .

# Build the Go application with Linux architecture
RUN GOOS=linux GOARCH=amd64 go build -o app

# Ensure the binary is executable
RUN chmod +x app

# Stage 2: Use prebuilt LaTeX image and add compiled binary
FROM prybruhta/my-latex-base AS runtime

WORKDIR /app

# Copy the compiled Go binary from the builder
COPY --from=builder /app/app /app/app

# Expose the port
EXPOSE 8080

# Run the server
CMD ["/app/app"]
