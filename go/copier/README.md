# Copier TUI

Interactive Bubble Tea application for orchestrating file migrations between two directories with resumable state, progress reporting, and Markdown summaries.

## Build & Run

```bash
cd go/copier
go test ./...           # optional once tests exist
go build ./cmd/copier   # outputs ./copier
./copier                # launches the TUI
```

During development you can skip the build step and run directly:

```bash
cd go/copier
go run ./cmd/copier
```

Set `GOCACHE=$(pwd)/.gocache` when working in sandboxes that block `$HOME/Library/Caches`.

## Features

- Guided TUI that gathers source/destination paths, detects existing `.migration.state.json`, and offers resume.
- Folder-aware copier that can target selected top-level directories, with graceful cancellation (Ctrl+C/Esc).
- Live progress dashboard showing totals, per-folder stats, and safe periodic state persistence.
- Markdown reports (`migration-report-<timestamp>.md` and per-folder `_migration_report.md`) summarizing successes/failures.

## Production Notes

- The binary never mutates sample directories; it copies only what you select in the UI.
- State is stored at `<destination>/.migration.state.json`. Keep that file with the destination if you plan to resume later.
- Ensure Poppler/Tesseract prerequisites from the Python tooling are installed when dealing with PDFs that require OCR after copying.
- Before packaging, run `gofmt ./...` and `go mod tidy` to keep dependencies minimal.
