# Gemini Project Overview: kdm Tools

This file provides a comprehensive overview of the `kdm-tools` repository for the Gemini AI assistant.

## Project Overview

This is a polyglot repository containing a collection of utility tools written in Python, Go, and PowerShell.

*   **Python (`kdm` CLI):** The core of the project is a Python-based command-line tool named `kdm` that provides various PDF and image manipulation functionalities.
*   **Go & PowerShell (Large File Management):** The repository also includes two implementations (one in Go and one in PowerShell) of a tool designed to find, report, and migrate large files within user profiles on Windows systems.

## Key Technologies

*   **Python:**
    *   `click` or `argparse`: For creating the command-line interface.
    *   `pdf2image`, `Pillow`, `PyPDF2`: For PDF and image processing.
    *   `pyproject.toml`: For project metadata and dependency management.
*   **Go:**
    *   `promptui`: For creating interactive command-line prompts.
    *   Standard library for file system operations.
*   **PowerShell:**
    *   Standard cmdlets for file and system interactions.

## Building and Running

### Python (`kdm` CLI)

1.  **Install Dependencies:**
    ```bash
    pip install -e ".[dev]"
    ```

2.  **Run the tool:**
    ```bash
    kdm --help
    ```

### Go (Large File Manager)

1.  **Navigate to the Go directory:**
    ```bash
    cd go
    ```

2.  **Run the application:**
    ```bash
    go run main.go
    ```

### PowerShell (Large File Manager)

1.  **Navigate to the PowerShell directory:**
    ```bash
    cd ps/Users
    ```

2.  **Execute the script:**
    ```powershell
    ./Manage-LargeUserFiles.ps1
    ```

## Development Conventions

*   **Python:**
    *   The main application logic is in the `tools/` directory.
    *   The CLI entry point is `tools/main.py`.
    *   Dependencies are managed in `pyproject.toml`.
*   **Go:**
    *   The main application logic is in `go/main.go`.
    *   Helper functions are located in `go/userfiles/`.
*   **PowerShell:**
    *   The main script is `ps/Users/Manage-LargeUserFiles.ps1`.
    *   Shared functions are in `ps/Users/UserFilesUtils.psm1`.

## Documentation

*   **File Server Migration Report Template:** Located at `docs/file-server-migration-report-template.md`, this Markdown file provides a template for generating reports on file server migrations, detailing server information, migration results, and summary statistics.
