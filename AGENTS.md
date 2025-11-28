# Repository Guidelines

## Project Structure & Module Organization
Python sources live in `tools/`, with CLI entrypoint `tools/main.py`, feature modules such as `pdf_to_images.py`, and shared helpers in `utils.py`. Acceptance-style tests live in `tests/` and mirror module names (`test_pdf_to_images.py`, etc.). Configuration such as `FIREBASE_KEY_PATH` is centralized in `config/settings.py`. Documentation, specs, and meeting artifacts reside in `docs/`, while experimental Go tooling is isolated in `go/` (`go run ./go` to exercise it). Keep assets, fixtures, and large binaries out of the repo; place temporary files under `ps/` or ignore them locally.

## Build, Test, and Development Commands
Install everything for local work via `pip install --user -e ".[dev]"` from the repo root. Run the CLI the same way production users do—`kdm pdf2images --input sample.pdf --output tmp/pages` or `python -m tools.main images2pdf`. Validate static analysis with `ruff check tools tests` and format with `black tools tests`. For the Go utilities, run `go fmt ./go/...` before `go run ./go`. Use `pyinstaller tools/main.py -n kdm` only when preparing distributable binaries.

## Coding Style & Naming Conventions
Python follows Black defaults (4-space indents, 88-char lines) and Ruff’s linting profile; keep imports sorted (`ruff check --select I`). Functions, variables, and files use `snake_case`, classes use `PascalCase`, and CLI subcommands remain lowercase verbs (`pdf2images`). Prefer pathlib, type hints, and explicit logging over print statements. Mirror existing module names (`mergepdfs`, `images_to_pdf`) when adding adjacent functionality, and document any new CLI flags in `README.md` and `USER_GUIDE.md`.

## Testing Guidelines
Pytest is the supported framework; place new suites under `tests/` as `test_<feature>.py` and keep fixtures local unless widely shared. Every PR should add or update tests covering success paths plus at least one failure mode (e.g., missing file, unreadable image). Run `pytest` for the full suite or `pytest tests/test_mergepdfs.py -k basic_merge` to target a scenario. Aim to preserve coverage for PDF/image transformations so regressions are caught before cutting releases.

## Commit & Pull Request Guidelines
Commit messages follow the concise, imperative style evident in `git log` (“Add Go implementation of large files manager”); scope one logical change per commit. Before opening a PR, ensure `black`, `ruff`, and `pytest` are clean, attach terminal samples for new CLI behaviors (e.g., `kdm images2pdf --help` output), and link the relevant issue or TODO. PR descriptions should list the user-facing change, validation commands, and any configuration updates (like new `.env` keys). Request review from another agent when touching deployment or Firebase paths, and wait for green CI before merging.

## Security & Configuration Tips
Never commit secrets—store Firebase Admin keys outside the repo and reference them via `FIREBASE_KEY` or `config/firebase-key.json` in `.env`. When testing Poppler- or Tesseract-dependent flows, guard OS-specific paths behind environment checks, and document required binaries in `docs/` for future agents. Review `requirements*.txt` whenever adding packages, and prefer existing dependencies before introducing new ones.
