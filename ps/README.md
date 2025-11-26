# PowerShell Scripts

Collection of PowerShell utilities for system administration and file management.

---

## ⚠️ Execution Policy Setup

Windows blocks PowerShell scripts by default for security. You need to allow script execution:

### Option 1: Run Individual Scripts (Recommended for beginners)
```powershell
# Right-click the .ps1 file → Properties → Check "Unblock" → OK
# Then run:
powershell -ExecutionPolicy Bypass -File .\ps\Users\Find-LargeUserFiles.ps1
```

### Option 2: Enable for Current User (One-time setup)
```powershell
# Run PowerShell as Administrator, then:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Option 3: Check Current Policy
```powershell
Get-ExecutionPolicy -List
```

---

## 📁 Available Scripts

### Users/
- **Find-LargeUserFiles.ps1** - Scans user directories for large files
  - Configurable size threshold (default: 200MB)
  - Excludes system folders (AppData, node_modules, etc.)
  - Generates formatted report

- **Move-LargeFilesToD.ps1** - Migrates large files from C:\Users to D:\Users
  - Copies files to D: preserving folder structure
  - Verifies copy using SHA256 hash comparison
  - Only deletes from C: after successful verification
  - Creates detailed operation log
  - Supports -WhatIf for preview mode

---

## 🚀 Usage Examples

### Find Large Files
```powershell
# Navigate to repo
cd C:\path\to\tools

# Run script
.\ps\Users\Find-LargeUserFiles.ps1

# When prompted, enter minimum size in MB (or press Enter for 200MB default)
```

### Move Large Files to D: Drive
```powershell
# Preview what would be moved (safe)
.\ps\Users\Move-LargeFilesToD.ps1 -MinSizeMB 500 -WhatIf

# Actually move files (interactive prompt for size)
.\ps\Users\Move-LargeFilesToD.ps1

# Move files 1GB+ without prompt
.\ps\Users\Move-LargeFilesToD.ps1 -MinSizeMB 1024
```

---

## 🛡️ Security Notes

- **RemoteSigned** policy allows local scripts to run but requires downloaded scripts to be signed
- **Bypass** temporarily runs a script without changing system policy
- Never run scripts from untrusted sources
- Always review script contents before execution

---

## 📝 Contributing

When adding new PowerShell scripts:
1. Add comprehensive help documentation using comment-based help
2. Include `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`
3. Use approved PowerShell verbs (Get-, Set-, New-, etc.)
4. Handle errors gracefully with try/catch
5. Group related scripts in subdirectories
