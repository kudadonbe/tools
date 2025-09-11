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

4. **Clone and install**:
    ```bash
    git clone https://github.com/kdmdonbe/tools.git
    cd tools
    pip install --user -e ".[dev]"
    ```

4. **(Optional but recommended)**: Add the per-user Python Scripts folder to your `PATH` so installed entry points (like `kdm`) are runnable from any shell.

        You can compute the exact Scripts folder for your Python installation from PowerShell and add it permanently to your User PATH. Example commands (PowerShell):

        ```powershell
        # show the per-user base (e.g. C:\Users\you\AppData\Roaming\Python)
        python -m site --user-base

        # compute the Scripts path automatically (prints the final folder)
        $base = (python -m site --user-base).Trim();
        $pyver = python -c "import sys; print('Python{}{}'.format(sys.version_info.major, sys.version_info.minor))";
        $scriptsPath = Join-Path (Join-Path $base $pyver) 'Scripts';
        Write-Output $scriptsPath
        ```

        Example output: `C:\Users\yourname\AppData\Roaming\Python\Python39\Scripts`

        To add that folder to your User PATH (permanent):

        ```powershell
        $userPath = [Environment]::GetEnvironmentVariable('PATH','User')
        if ($userPath -notlike "*$scriptsPath*") {
            [Environment]::SetEnvironmentVariable('PATH', "$userPath;$scriptsPath", 'User')
            Write-Output "Added to User PATH. Restart your shell or sign out/in to apply." 
        } else {
            Write-Output "Scripts path already present in User PATH."
        }
        ```

        > This lets you run `kdm` globally in PowerShell or CMD. You can still run it locally using `./kdm` even without adding to PATH.

5. **Set PYTHONPATH if needed**:

        If you see `ModuleNotFoundError: No module named 'tools'` while working in the repo, it's often because Python's import search path doesn't include the repository root. Two recommended fixes:

        - Preferred: install the package in editable mode (above) so imports and console scripts work without tweaking PYTHONPATH:

            ```powershell
            python -m pip install --user -e ".[dev]"
            ```

        - Quick/dev-only: set `PYTHONPATH` to the repository root (not to the nested `tools` folder):

            ```powershell
            # temporary (current session only)
            $env:PYTHONPATH = "C:\Users\developer\OneDrive\Documents\GitHub\tools"

            # permanent (User environment variable)
            [Environment]::SetEnvironmentVariable('PYTHONPATH', 'C:\Users\developer\OneDrive\Documents\GitHub\tools', 'User')
            ```

        Important: set `PYTHONPATH` to the repository root (for example `C:\Users\...\GitHub\tools`) and NOT to the nested `...\tools\tools` directory. Pointing at `...\tools\tools` will make Python look for `...\tools\tools\tools` when you `import tools`, which is incorrect and the most common source of confusion.

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

