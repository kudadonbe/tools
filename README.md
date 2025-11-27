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

1. **Ensure Python is installed** (Python 3.8+ required).
   > You can install it using your OS's package manager (e.g. Homebrew or apt), or from https://www.python.org

2. **Install Poppler**:
    ```bash
    brew install poppler  # macOS
    sudo apt install poppler-utils  # Linux
    ```

3. **Clone the repository**:
    ```bash
    git clone https://github.com/kudadonbe/tools.git
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

7. **Make sure your PATH includes user scripts** (adjust Python version if needed):
    ```bash
    export PATH="$PATH:$HOME/Library/Python/3.x/bin"
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
    git clone https://github.com/kudadonbe/tools.git
    cd tools
    pip install --user -e ".[dev]"
    ```

4. **(Optional but recommended)**: Add the scripts path to your PATH:
    ```
    %USERPROFILE%\AppData\Roaming\Python\Python3xx\Scripts\
    ```
    > This lets you run `kdm` globally in PowerShell or CMD. You can still run it locally using `.\kdm` even without adding to PATH.

5. **Set PYTHONPATH if needed**:
    ```powershell
    $env:PYTHONPATH = "$(Get-Location)"
    ```
    Or add it permanently in **Environment Variables** → User variables:
    - **Name**: `PYTHONPATH`
    - **Value**: `Full\Path\To\tools` (e.g. `C:\Users\yourname\Documents\GitHub\tools`)

6. **Test**:
    ```powershell
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
    Make sure your Python user scripts directory is in your `PATH`, e.g.:
    ```
    %USERPROFILE%\AppData\Roaming\Python\Python3xx\Scripts\
    ```

