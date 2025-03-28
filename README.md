
# Kuda Tools - PDF & Image Utilities

## Setup Instructions

Kuda Tools is a set of utilities for working with PDFs and images. It allows you to convert PDF pages to images and merge images into a single PDF.

### Requirements
- Python 3.8 or higher
- Poppler (for `pdf2image` conversion)

---

## Installation

### macOS & Linux

1. **Install Python 3** (skip if already installed):
   - **macOS**:
     ```bash
     brew install python
     ```
   - **Linux** (Ubuntu/Debian):
     ```bash
     sudo apt update
     sudo apt install python3 python3-pip
     ```

2. **Install Poppler** (Required for `pdf2image` to work):
   - **macOS**:
     ```bash
     brew install poppler
     ```
   - **Linux** (Ubuntu/Debian):
     ```bash
     sudo apt install poppler-utils
     ```

3. **Clone the repository**:
   ```bash
   git clone https://github.com/kudadonbe/tools.git
   cd tools
   ```

4. **Install dependencies**:
   ```bash
   pip3 install --user -e .[dev]
   ```

5. **Set up the `PATH`**:
   Add the following to your `.zshrc` or `.bash_profile`:
   ```bash
   export PATH="$PATH:/Users/yourusername/Library/Python/3.13/bin"
   ```
   Apply the changes:
   ```bash
   source ~/.zshrc  # Or ~/.bash_profile
   ```

6. **Test the tool**:
   ```bash
   kuda --help
   ```

---

### Windows

1. **Install Python 3**:
   - Download from [official Python website](https://www.python.org/downloads/).
   - During installation, select **"Add Python to PATH"**.

2. **Install Poppler**:
   - Download Poppler from [Poppler Windows](https://github.com/oschwartz10612/poppler-windows/releases/).
   - Extract the zip to a location like `C:\poppler\poppler-xx.x.x\`.

   - **Add Poppler to `PATH`**:
     - Search **Environment Variables** in Start Menu.
     - Select **Edit the system environment variables**.
     - Click **Environment Variables**, then edit **Path** under **System variables**.
     - Add a new entry for Poppler's `bin` folder:
       ```
       C:\poppler\poppler-xx.x.x\bin
       ```

3. **Clone the repository**:
   ```bash
   git clone https://github.com/kudadonbe/tools.git
   cd tools
   ```

4. **Install dependencies**:
   ```bash
   pip install -e .[dev]
   ```

5. **Test the tool**:
   ```bash
   kuda --help
   ```

---

## Usage

- **Convert PDF to images**:
  ```bash
  kuda pdf2images
  ```

- **Merge images into PDF**:
  ```bash
  kuda images2pdf
  ```

---

## Development

1. Clone:
   ```bash
   git clone https://github.com/kudadonbe/tools.git
   ```

2. Install dependencies:
   ```bash
   pip install -e .[dev]
   ```

3. Modify and run:
   ```bash
   kuda pdf2images
   ```

4. Commit changes:
   ```bash
   git add .
   git commit -m "Your commit message"
   git push origin main
   ```

---

## Troubleshooting

Ensure:
- Poppler is installed and in `PATH`.
- Python >=3.8.
- Dependencies installed (`pip install --user -e .[dev]`).
