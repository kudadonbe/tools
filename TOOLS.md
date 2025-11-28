# Tools Repository

Multi-language developer toolset for PDF/image utilities and system administration.

---

## 📦 Projects

### 1. **kdm** - Python PDF & Image Utilities
Location: `tools/` directory

CLI tools for PDF and image manipulation:
- Convert PDFs to images
- Merge images into PDFs  
- Compress PDFs
- Align PDFs with OCR
- Merge multiple PDFs

**Installation:**
```bash
pip install --user -e ".[dev]"
kdm --help
```

---

### 2. **PowerShell Scripts**
Location: `ps/` directory

System administration utilities for Windows.

#### Users/
- **Manage-LargeUserFiles.ps1** ⭐ (Recommended - Interactive TUI)
  - Scan and generate reports for large files
  - Migrate files from C: to D: drive with verification
  - Perfect for managing Teams recordings
  
- **Find-LargeUserFiles.ps1** - Report-only scanner
- **Move-LargeFilesToD.ps1** - Migration tool

**Shared Module:** `UserFilesUtils.psm1` provides reusable functions

**Usage:**
```powershell
.\ps\Users\Manage-LargeUserFiles.ps1
```

---

### 3. **Go Large Files Manager**
Location: `go/` directory

Compiled Go implementation of large files management tool.

**Features:**
- ✅ Standalone binary (no dependencies)
- ✅ Interactive TUI with color output
- ✅ Cross-platform (Windows, Linux, macOS)
- ✅ SHA256 hash verification
- ✅ ~4MB compiled size

**Building:**
```bash
cd go
go build -ldflags="-s -w" -o userfiles-manager.exe .
```

**Running:**
```bash
.\go\userfiles-manager.exe
```

**Cross-compile:**
```bash
# Linux
GOOS=linux GOARCH=amd64 go build -o userfiles-manager-linux .

# macOS
GOOS=darwin GOARCH=amd64 go build -o userfiles-manager-mac .
```

---

## 🎯 Quick Comparison

| Feature | PowerShell | Go Binary |
|---------|-----------|-----------|
| Dependencies | PowerShell 5.1+ | None (standalone) |
| Platform | Windows | Windows/Linux/macOS |
| Size | Scripts (~15KB) | Binary (~4MB) |
| Startup | Instant | Instant |
| Execution Policy | May require bypass | No restrictions |

---

## 📚 Documentation

- Python tools: `README.md` (root)
- PowerShell scripts: `ps/README.md`
- Go tool: `go/README.md`

---

## 🛡️ Safety Features

All file management tools include:
- ✅ Comprehensive exclusion lists (AppData, cloud sync, dev tools)
- ✅ SHA256 hash verification before deletion
- ✅ Copy-then-delete approach (never move)
- ✅ Detailed logging
- ✅ Graceful handling of locked files
- ✅ WhatIf/preview modes

---

## 🚀 Getting Started

1. **For PDF/Image work:** Use Python `kdm` CLI
2. **For file management (Windows users):** Use PowerShell scripts
3. **For file management (any platform):** Use Go binary
4. **For integration into other tools:** Import Go as a module

---

## 📝 Contributing

When adding new scripts:
- PowerShell: Use shared `UserFilesUtils.psm1` module
- Go: Extend `userfiles` package
- Python: Follow existing `kdm` structure

---

## 📄 License

MIT License - see LICENSE file for details
