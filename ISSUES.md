# ISSUES / TODO (developer-facing)

This file lists known issues, missing documentation, and recommended fixes to make development and onboarding smoother.

Priority legend:
- P0: High — blocks correct behavior or causes runtime errors
- P1: Medium — important to document or fix for dev UX
- P2: Low — nice-to-have

## P0 - CLI correctness (code fixes)
- File: `tools/main.py`
  - Problem: `argparse` usage is fragile: `parser.parse_args()` is called before checking `len(sys.argv)`, so running without args may error out. `choices` excludes 'version' and 'help' but code checks for them.
  - Problem: Command names inconsistent between `main.py` (`merge`) and `mergepdfs.py` click command (`mergepdfs`). This leads to confusion and broken CLI calls.
  - Suggested fix: Use `argparse` subparsers or switch entirely to `click` for consistent subcommands. Ensure `pyproject.toml` entry point (`kdm = tools.main:main`) matches subcommand names documented in README.

## P0 - External system binaries required (document & verify)
- `pytesseract` / `ocrmypdf` require Tesseract-OCR installed and on PATH (or configured via `pytesseract.pytesseract.tesseract_cmd`). Add Windows install steps and link.
- `pikepdf` / `ocrmypdf` may require `qpdf` on PATH. Document how to install on Windows.
- `pdf2image` requires Poppler (already in README) — ensure the `Library\bin` path is emphasized for Windows.

## P1 - Tkinter usage
- Files: `tools/pdf_to_images.py`, `tools/images_to_pdf.py`, `tools/mergepdfs.py`
  - Problem: They use `tkinter` for file/folder pickers. Some Windows Python installs do not include Tcl/Tk by default.
  - Suggested action: Add a short note in README explaining how to install Python from python.org (which includes Tcl/Tk) or how to install Tcl/Tk separately.

## P1 - README clarifications (already partially updated)
- Ensure README shows:
  - Exact `pip install --user -e "[dev]"` usage and that the per-user `Scripts` folder is added to User PATH.
  - Show how to compute the exact Scripts path via `python -m site --user-base` (PowerShell snippet present).
  - Add Tesseract and QPDF install instructions and links.

## P1 - Windows build tools
- Note: Some packages may require Visual C++ Build Tools. Add a short troubleshooting hint and link to the Microsoft Build Tools installer.

## P1 - Tests / CI
- There are no automated tests yet. Add a small smoke test (pytest) that:
  - Imports `tools` package
  - Calls `tools.main` with `--help` or runs the `kdm` entry point to ensure importable

## P2 - Developer workflow recommendations
- Recommend adding a short section showing how to create and use a local venv for development:
  - `python -m venv .venv` / `.\.venv\Scripts\Activate.ps1` / `pip install -e "[dev]"`
- Consider adding a `Makefile` or `tasks.json` with common developer tasks (install, test, lint).

## Suggested immediate code changes (small PRs)
1. Fix `tools/main.py` to use subparsers and to accept `--version` and `help` flags without conflicting with `choices`.
2. Align command name `merge` vs `mergepdfs` (pick one) and update `pyproject.toml`/`README.md` accordingly.
3. Add README entries for Tesseract and QPDF.

## Notes
- `pyproject.toml` already defines `kdm = tools.main:main` and `dev` extras; ensure packaging includes any data files if needed later.

---
Edit this file as you work through items. Mark items DONE when fixed.
