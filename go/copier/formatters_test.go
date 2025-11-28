package copier

import (
	"testing"
	"time"
)

func TestFormatBytes(t *testing.T) {
	tests := []struct {
		bytes    int64
		expected string
	}{
		{512, "512 B"},
		{1024, "1.0 KB"},
		{1048576, "1.0 MB"},
	}

	for _, tt := range tests {
		if got := formatBytes(tt.bytes); got != tt.expected {
			t.Fatalf("formatBytes(%d) = %s, want %s", tt.bytes, got, tt.expected)
		}
	}
}

func TestFormatDuration(t *testing.T) {
	d := 2*time.Hour + 5*time.Minute + 9*time.Second
	if got := formatDuration(d); got != "02:05:09" {
		t.Fatalf("formatDuration(%s) = %s, want 02:05:09", d, got)
	}
}

func TestFormatTime(t *testing.T) {
	ts := time.Date(2025, 1, 2, 3, 4, 5, 0, time.UTC)
	if got := formatTime(ts); got != "2025-01-02 03:04:05" {
		t.Fatalf("formatTime() = %s", got)
	}
	if got := formatTime(time.Time{}); got != "N/A" {
		t.Fatalf("formatTime zero = %s, want N/A", got)
	}
}
