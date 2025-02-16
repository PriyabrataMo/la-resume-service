# Base Image: Debian with full LaTeX support (pdflatex, xelatex, lualatex)
FROM debian:latest AS latex-base

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    texlive-latex-base \
    texlive-latex-recommended \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-latex-extra \
    texlive-xetex \
    texlive-luatex \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Stage 1: Build Go Application
FROM golang:1.24 AS builder

WORKDIR /app

# Copy and install dependencies
COPY go.mod go.sum ./
RUN go mod tidy && go mod download

# Copy the project source code
COPY . .

# Build the Go application with Linux architecture (Static binary)
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o app

# Ensure the binary is executable
RUN chmod +x app

# Stage 2: Final Runtime Image with LaTeX and Go App
FROM latex-base AS runtime

WORKDIR /app

# Copy the compiled Go binary from the builder stage
COPY --from=builder /app/app /app/app

# Expose the port
EXPOSE 8080

# Run the server
CMD ["/app/app"]
