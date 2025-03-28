
# kdm Tools - Developer Setup

🛠️ `kdm` is a developer toolset for PDF and image utilities, including converting PDFs to images and merging images into a PDF. This README is focused on contributors and development setup.

---

## Requirements

- Python 3.8 or higher
- Poppler (for `pdf2image`)
- Git

---

## 🔧 Local Development Setup

### macOS & Linux

1. **Install Python** (if not already installed):
    ```bash
    brew install python  # macOS
    sudo apt install python3 python3-pip  # Linux
    ```

2. **Install Poppler**:
    ```bash
    brew install poppler  # macOS
    sudo apt install poppler-utils  # Linux
    ```

3. **Clone the repository**:
    ```bash
    git clone https://github.com/kdmdonbe/tools.git
    cd tools
    ```

4. **Install dependencies** in editable mode:
    ```bash
    pip install --user -e ".[dev]"
    ```

5. **Add project path to Python if needed** (fixes `ModuleNotFoundError`):
    ```bash
    export PYTHONPATH="$PYTHONPATH:$(pwd)"
    ```

6. **(Optional)** Add the above to `.zshrc` or `.bashrc`:
    ```bash
    export PYTHONPATH="$PYTHONPATH:$HOME/Documents/GitHub/tools"
    ```

7. **Make sure your PATH includes user scripts**:
    ```bash
    export PATH="$PATH:$HOME/Library/Python/3.13/bin"  # macOS (adjust Python version if needed)
    ```

8. **Test the CLI**:
    ```bash
    kdm --help
    ```

---

### Windows

1. **Install Python** from [python.org](https://www.python.org/downloads/)
   - ✅ Ensure "Add Python to PATH" is selected

2. **Download and install Poppler**:
   - [Poppler for Windows](https://github.com/oschwartz10612/poppler-windows/releases/)
   - Extract and place in a permanent folder (e.g., `C:\Tools\poppler`)
   - Add `C:\Tools\poppler\Library\bin` to your system `PATH`

3. **Clone and install**:
    ```bash
    git clone https://github.com/kdmdonbe/tools.git
    cd tools
    pip install --user -e ".[dev]"
    ```

4. **If using PowerShell or CMD**, ensure `%USERPROFILE%\AppData\Roaming\Python\PythonXX\Scripts` is in PATH

5. **Test**:
    ```bash
    kdm --help
    ```

---

## 🧪 Commands

- Convert PDF to images:
    ```bash
    kdm pdf2images
    ```

- Merge images to PDF:
    ```bash
    kdm images2pdf
    ```

---

## 💻 Development Flow

```bash
# Make changes in the tools/ directory
git add .
git commit -m "Message"
git push origin main
```

---

## ⚠️ Troubleshooting

- `ModuleNotFoundError: No module named 'tools'`?
    ```bash
    export PYTHONPATH="$PYTHONPATH:$(pwd)"
    ```

- `kdm: command not found`?
    Make sure your Python user scripts directory is in your `PATH`.

---
