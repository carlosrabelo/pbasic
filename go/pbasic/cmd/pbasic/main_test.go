package main

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

func TestCLIArgumentDispatch(t *testing.T) {
	// Build temporary binary for testing CLI dispatch
	tempDir := t.TempDir()
	binPath := filepath.Join(tempDir, "pbasic")

	cmdBuild := exec.Command("go", "build", "-o", binPath, ".")
	if err := cmdBuild.Run(); err != nil {
		t.Fatalf("failed to build binary for test: %v", err)
	}

	t.Run("missing file returns error and exit code 1", func(t *testing.T) {
		cmd := exec.Command(binPath, "non_existent_file.bas")
		var stderr strings.Builder
		cmd.Stderr = &stderr
		err := cmd.Run()
		if err == nil {
			t.Fatalf("expected error for non-existent file, got nil")
		}
		if !strings.Contains(stderr.String(), "Cannot open file: non_existent_file.bas") {
			t.Errorf("unexpected stderr: %q", stderr.String())
		}
	})

	t.Run("existing file exits cleanly with code 0", func(t *testing.T) {
		tempFile := filepath.Join(tempDir, "test.bas")
		if err := os.WriteFile(tempFile, []byte("10 PRINT 1\n"), 0644); err != nil {
			t.Fatalf("failed to create temp file: %v", err)
		}

		cmd := exec.Command(binPath, tempFile)
		if err := cmd.Run(); err != nil {
			t.Fatalf("expected clean exit for existing file, got: %v", err)
		}
	})

	t.Run("interactive mode banner without arguments", func(t *testing.T) {
		cmd := exec.Command(binPath)
		out, err := cmd.Output()
		if err != nil {
			t.Fatalf("expected clean exit without arguments, got: %v", err)
		}
		if !strings.Contains(string(out), "PBasic") {
			t.Errorf("expected banner PBasic, got %q", string(out))
		}
	})
}
