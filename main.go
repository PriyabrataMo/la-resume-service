package main

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/gin-gonic/gin"
)

// Set Gin to release mode at startup
func init() {
	gin.SetMode(gin.ReleaseMode)
}

func main() {
	r := gin.Default()
	r.POST("/compile-latex", compileLatex)
	r.GET("/ping", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "pong"})
	})
	r.Run(":8080") // Start the server on port 8080
}

func compileLatex(c *gin.Context) {
	// Get uploaded LaTeX file
	file, err := c.FormFile("latex")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "File upload failed"})
		return
	}

	// Define file paths
	latexFilePath := filepath.Join(os.TempDir(), "document.tex")
	pdfFilePath := filepath.Join(os.TempDir(), "document.pdf")

	// Save LaTeX file locally
	if err := c.SaveUploadedFile(file, latexFilePath); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save LaTeX file"})
		return
	}

	// Compile LaTeX to PDF using XeLaTeX
	cmd := exec.Command("pdflatex", "-interaction=nonstopmode", "-output-directory="+os.TempDir(), latexFilePath)
	//cmd := exec.Command("xelatex", "-interaction=nonstopmode", "-output-directory="+os.TempDir(), latexFilePath)

	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &out

	if err := cmd.Run(); err != nil {
		fmt.Println(out.String()) // Debugging output
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to compile LaTeX",
			"details": out.String(), // Show compilation error details
		})
		return
	}

	// Open the generated PDF file
	pdfFile, err := os.Open(pdfFilePath)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to open PDF file"})
		return
	}
	defer pdfFile.Close()

	// Send PDF as response
	c.Header("Content-Disposition", "attachment; filename=document.pdf")
	c.Header("Content-Type", "application/pdf")
	io.Copy(c.Writer, pdfFile)

	// Cleanup temporary files
	_ = os.Remove(latexFilePath)
	_ = os.Remove(pdfFilePath)
}
