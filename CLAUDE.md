# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a polyglot repository containing utility tools in three languages:

- **Python (`kdm` CLI)**: PDF and image manipulation tools (pdf2image, images2pdf, merge, compress, align)
- **Go (Large File Manager)**: Interactive TUI for scanning, reporting, and migrating large files on Windows systems
- **PowerShell (Large File Manager)**: Alternative PowerShell implementation of the file management tool

## Development Commands

### Python (`kdm` CLI)

**Setup:**
```bash
pip install --user -e ".[dev]"
```

**Run the CLI:**
```bash
kdm --help
kdm pdf2images          # Convert PDF to images
kdm images2pdf          # Merge images to PDF
kdm merge               # Merge multiple PDFs
python -m tools.main    # Alternative way to run
```

**Testing:**
```bash
pytest                                    # Run all tests
pytest tests/test_pdf_to_images.py       # Run specific test file
pytest tests/test_mergepdfs.py -k basic_merge  # Run specific test
```

**Linting & Formatting:**
```bash
ruff check tools tests              # Lint code
ruff check --select I tools tests   # Check import sorting
black tools tests                   # Format code
```

**Build Executable:**
```bash
pyinstaller tools/main.py -n kdm
```

### Go (Large File Manager)

**Build:**
```bash
cd go
go build -o userfiles-manager.exe .                    # Windows
GOOS=linux GOARCH=amd64 go build -o userfiles-manager-linux .   # Linux
GOOS=darwin GOARCH=amd64 go build -o userfiles-manager-mac .    # macOS
```

**Build optimized standalone binary:**
```bash
go build -ldflags="-s -w" -o userfiles-manager.exe .
```

**Run:**
```bash
go run main.go          # From go/ directory
go run ./go             # From repository root
```

**Format:**
```bash
go fmt ./go/...
```

**Install dependencies:**
```bash
go mod download
```

### PowerShell (Large File Manager)

**Run:**
```powershell
cd ps/Users
./Manage-LargeUserFiles.ps1
```

## Architecture

### Python Tool Structure

- **Entry Point**: `tools/main.py` uses `argparse` to dispatch to subcommand modules
- **Feature Modules**: Each command is a separate module (`pdf_to_images.py`, `images_to_pdf.py`, `mergepdfs.py`, `alignpdf.py`, `compresspdf.py`)
- **Shared Utilities**: `tools/utils.py` contains shared helper functions
- **Configuration**: `config/settings.py` centralizes environment variables (e.g., `FIREBASE_KEY_PATH`)
- **Tests**: Mirror module structure in `tests/` directory (`test_pdf_to_images.py`, etc.)
- **Package Definition**: `pyproject.toml` defines dependencies, metadata, and the `kdm` entry point

### Python Module Pattern

Each feature module follows this pattern:
- Interactive mode (with `questionary` prompts) vs. non-interactive mode (using defaults)
- File selection via `tkinter.filedialog`
- Support for multiple output formats and quality settings
- Uses `pdf2image`, `Pillow`, `PyPDF2`, and related libraries

### Go Tool Structure

- **Entry Point**: `go/main.go` provides interactive TUI menu using `promptui`
- **Core Logic**: `go/userfiles/userfiles.go` contains file scanning, reporting, and migration functions
- **Features**: SHA256 verification, safe copy-then-delete approach, comprehensive exclusion list
- **Dependencies**: `github.com/fatih/color` for terminal colors, `github.com/manifoldco/promptui` for prompts

### PowerShell Tool Structure

- **Main Script**: `ps/Users/Manage-LargeUserFiles.ps1`
- **Helper Functions**: Shared functions in `ps/Users/UserFilesUtils.psm1` (if present)
- **Individual Scripts**: `Find-LargeUserFiles.ps1`, `Move-LargeFilesToD.ps1`

## Key Dependencies

### Python
- **PDF/Image Processing**: `pdf2image`, `pillow`, `pytesseract`, `ocrmypdf`, `pikepdf`, `pypdf`
- **CLI**: `argparse`, `questionary`, `click`, `tqdm`
- **Cloud**: `firebase-admin` (requires Firebase Admin SDK key at `config/firebase-key.json` or path in `FIREBASE_KEY` env var)
- **Dev Tools**: `pytest`, `black`, `ruff`, `pyinstaller`

### Go
- Requires Go 1.21+
- `github.com/fatih/color` - Terminal colors
- `github.com/manifoldco/promptui` - Interactive prompts

### External Tools
- **Poppler**: Required for `pdf2image` (install via `brew install poppler` on macOS or `apt install poppler-utils` on Linux)
- **Tesseract**: Required for OCR features (install via package manager)

## CI/CD

### Python CI (`.github/workflows/build-python.yml`)
Runs on push/PR to `main`:
1. Installs dependencies with `pip install -e ".[dev]"`
2. Lints with `ruff check .`
3. Tests with `pytest`

### Go CI (`.github/workflows/build-go.yml`)
Builds cross-platform binaries on push/PR to `main`:
- Targets: Linux, Windows, macOS (amd64, arm64)
- Creates release artifacts when tags starting with `v*` are pushed
- Uploads binaries as GitHub release assets

## Coding Standards

- **Python**: Follow Black defaults (4-space indents, 88-char lines), Ruff linting profile
- **Naming**: `snake_case` for functions/variables/files, `PascalCase` for classes, lowercase for CLI commands
- **Imports**: Keep sorted (use `ruff check --select I`)
- **Type Hints**: Prefer explicit type hints and pathlib over string paths
- **Logging**: Use explicit logging over print statements

## Configuration & Secrets

- **Firebase**: Store Firebase Admin SDK key outside the repo; reference via `FIREBASE_KEY` environment variable or `config/firebase-key.json`
- **Environment Variables**: Loaded via `python-dotenv` from `.env` file
- Never commit secrets, API keys, or credentials

## File Organization

- `tools/` - Python source code
- `go/` - Go implementation
- `ps/` - PowerShell scripts
- `tests/` - Python test suite
- `config/` - Configuration files (settings, Firebase keys)
- `docs/` - Documentation, specs, meeting notes
- `.github/workflows/` - CI/CD configurations

## Migration & Documentation

The `docs/` directory contains:
- `file-server-migration-report-template.md` - Template for file server migration reports
- `file-copy-migration-plan.md` - Migration planning documentation

The `SESSION_NOTES.md` file tracks development session notes and decisions.
