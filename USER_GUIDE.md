# 📋 Report & File Migration Tool - User Guide

## 🎯 Purpose

The **Report & File Migration Tool** helps you manage disk space by finding large files in your Windows user directory and safely moving them to a secondary drive (D:) while keeping them accessible in the same folder structure.

**Perfect for:**
- 📹 Microsoft Teams meeting recordings taking up space on C: drive
- 🎬 Large video files, ISOs, and backups
- 📦 Downloaded installers and archives
- 💾 Freeing up your main system drive without losing files

---

## 🌟 Key Features

### ✅ Safety First
- **SHA256 Verification**: Every file is verified after copying before deletion
- **Copy-Then-Delete**: Never moves files directly - always copies first, then deletes original
- **Smart Exclusions**: Automatically skips system folders, cloud sync, and development tools
- **Preview Mode**: See what would be moved before committing

### 🔍 Smart Scanning
- Configurable file size threshold (default: 200MB+)
- Excludes protected system areas (AppData, OneDrive, node_modules, etc.)
- Generates detailed reports with file locations and sizes
- Identifies candidates for migration

### 📦 Three Implementation Options
Choose the version that works best for you:
1. **PowerShell Interactive** - User-friendly menu interface (Windows)
2. **PowerShell Scripts** - Individual command-line scripts (Windows)
3. **Go Binary** - Standalone executable (Windows, Linux, macOS)

---

## 🚀 Quick Start

### Option 1: PowerShell Interactive Tool ⭐ **RECOMMENDED**

**For:** Windows users who want an easy, menu-driven experience

**Steps:**
1. Open PowerShell
2. Navigate to the tools directory:
   ```powershell
   cd C:\path\to\tools
   ```
3. Run the interactive manager:
   ```powershell
   .\ps\Users\Manage-LargeUserFiles.ps1
   ```
4. Choose from the menu:
   - **[1]** Scan and generate report only
   - **[2]** Scan and move files to D: drive
   - **[3]** Exit

**Example Session:**
```
================================================================================
  LARGE USER FILES MANAGER
================================================================================

What would you like to do?

  [1] Scan and generate report only
  [2] Scan and move files to D: drive
  [3] Exit

Selection: 1

Enter minimum file size in MB:
(Press Enter for default: 200MB)

Size (MB): 500

Scanning C:\Users for files larger than 500MB...
✓ Report generated: LargeUserFiles_20251127_094523.txt
```

---

### Option 2: Individual PowerShell Scripts

**For:** Windows users who prefer command-line control or scripting

#### Step 1: Find Large Files (Report Only)
```powershell
.\ps\Users\Find-LargeUserFiles.ps1
```
- Prompts for minimum file size
- Generates report: `LargeUserFiles_[timestamp].txt`
- No files are modified

#### Step 2: Move Files (Optional)
```powershell
# Preview what would be moved (safe)
.\ps\Users\Move-LargeFilesToD.ps1 -MinSizeMB 500 -WhatIf

# Actually move files
.\ps\Users\Move-LargeFilesToD.ps1 -MinSizeMB 500
```

**Parameters:**
- `-MinSizeMB <number>`: Minimum file size in megabytes (default: prompts user)
- `-WhatIf`: Preview mode - shows what would happen without making changes

---

### Option 3: Go Binary (Cross-Platform)

**For:** Users on any platform or those who want a standalone executable

#### Build the Binary (one-time):
```bash
cd go
go build -ldflags="-s -w" -o userfiles-manager.exe .
```

#### Run:
```bash
.\go\userfiles-manager.exe
```

**Features:**
- ✅ No dependencies required
- ✅ Works on Windows, Linux, macOS
- ✅ Same interactive menu as PowerShell version
- ✅ Color-coded output
- ✅ ~4MB standalone binary

---

## 📖 Detailed Usage Instructions

### Understanding the Scan Report

When you run a scan, you'll get a report like this:

```
LARGE FILES IN C:\USERS - Report Generated: 2025-11-27 09:45:23
Minimum Size: 200MB

FILES FOUND (15 files, Total Size: 23.45 GB):
================================================================================

File: C:\Users\John\Videos\TeamsMeetings\Recording_20251120.mp4
Size: 1,234.56 MB
Last Modified: 2025-11-20 14:30:15

File: C:\Users\John\Downloads\ubuntu-22.04.iso
Size: 3,456.78 MB
Last Modified: 2025-11-15 10:22:33

[... more files ...]

SUMMARY:
Total Files: 15
Total Size: 23.45 GB
Scan Duration: 12.3 seconds
```

**What to do next:**
- Review the files listed
- Decide which ones you want to migrate
- Note the total size to ensure D: drive has enough space

---

### Migrating Files to D: Drive

**Before You Start:**
1. ✅ Ensure D: drive exists and has enough free space
2. ✅ Close any programs using the files (Teams, video players, etc.)
3. ✅ Review the scan report to know what will be moved

**The Migration Process:**

1. **Copy Phase:**
   - Files are copied to `D:\Users\[YourUsername]\...`
   - Original folder structure is preserved
   - Example: `C:\Users\John\Videos\Meeting.mp4` → `D:\Users\John\Videos\Meeting.mp4`

2. **Verification Phase:**
   - SHA256 hash calculated for source file
   - SHA256 hash calculated for destination file
   - Hashes must match exactly

3. **Deletion Phase:**
   - Original file deleted from C: only after successful verification
   - If verification fails, original kept, error logged

4. **Logging:**
   - Detailed log created: `MoveLog_[timestamp].txt`
   - Records every operation, success/failure, and hash values

**Example Migration Log:**
```
[2025-11-27 10:15:23] Starting migration process
[2025-11-27 10:15:24] Copying: C:\Users\John\Videos\Meeting.mp4
[2025-11-27 10:15:45] Copy complete: D:\Users\John\Videos\Meeting.mp4
[2025-11-27 10:15:46] Verifying hash...
[2025-11-27 10:15:48] Hash match confirmed
[2025-11-27 10:15:48] Deleted original: C:\Users\John\Videos\Meeting.mp4
[2025-11-27 10:15:48] ✓ Successfully migrated (1.23 GB)
```

---

## 🛡️ What Files Are Protected?

The tool **NEVER** touches these locations:

### System & Application Data
- `AppData` - Application settings and data
- `Application Data` - Legacy app data
- `.cache`, `.config`, `.local` - Program caches and configs

### Cloud Sync Folders
- `OneDrive`, `OneDrive - *` - Microsoft cloud storage
- `Dropbox` - Dropbox sync folder
- `Google Drive` - Google Drive sync folder
- `iCloud Drive` - Apple cloud storage

### Development Tools
- `node_modules` - Node.js packages
- `.git`, `.svn`, `.hg` - Version control
- `venv`, `env`, `.venv` - Python virtual environments
- `bin`, `obj` - Build artifacts

### System Folders
- `Windows`, `System32` - Windows core files
- `Program Files`, `Program Files (x86)` - Installed programs

**Result:** Only your personal files (Documents, Downloads, Videos, Pictures, Desktop) are scanned and migrated.

---

## 💡 Common Use Cases

### Case 1: Teams Meeting Recordings Filling C: Drive

**Problem:** Teams recordings in `C:\Users\[You]\Videos\TeamsMeetings` taking up 10GB+

**Solution:**
```powershell
# Run interactive tool
.\ps\Users\Manage-LargeUserFiles.ps1

# Select option 2 (Scan and move)
# Enter 200 MB threshold
# Files moved to D:\Users\[You]\Videos\TeamsMeetings
# C: drive space freed immediately
```

**Result:** Recordings accessible at new location, C: drive cleaned up

---

### Case 2: Downloaded ISOs and Large Installers

**Problem:** Downloaded files in `C:\Users\[You]\Downloads` wasting space

**Solution:**
```powershell
# Preview first
.\ps\Users\Move-LargeFilesToD.ps1 -MinSizeMB 500 -WhatIf

# Review preview output
# Then execute
.\ps\Users\Move-LargeFilesToD.ps1 -MinSizeMB 500
```

**Result:** Large downloads moved to D:, smaller files stay on C:

---

### Case 3: Video Projects and Media Files

**Problem:** Video editing projects consuming 50GB+ on system drive

**Solution:**
```powershell
# Use higher threshold for very large files
.\ps\Users\Manage-LargeUserFiles.ps1

# Select option 2
# Enter 1000 MB (1GB) threshold
# Only files 1GB+ will be migrated
```

**Result:** Massive files moved to D:, keeps system drive responsive

---

## ⚙️ Advanced Configuration

### Customizing File Size Threshold

**Interactive Mode:**
- You'll be prompted each time you run

**Script Mode:**
```powershell
# Move files 100MB and larger
.\ps\Users\Move-LargeFilesToD.ps1 -MinSizeMB 100

# Move files 5GB and larger
.\ps\Users\Move-LargeFilesToD.ps1 -MinSizeMB 5120
```

**Go Binary:**
- Enter size when prompted, or press Enter for default (200MB)

---

### Modifying Exclusion List

If you need to customize what's excluded:

**PowerShell:**
Edit `ps\Users\UserFilesUtils.psm1` - find the `$excludedPaths` array

**Go:**
Edit `go\userfiles\scanner.go` - find the `excludedPaths` variable

**Default exclusions cover 99% of use cases - modify only if necessary**

---

## 🔧 Troubleshooting

### Issue: "Execution Policy" Error (PowerShell)

**Error:**
```
.\Manage-LargeUserFiles.ps1 : File cannot be loaded because running scripts is disabled
```

**Solution:**
```powershell
# Run PowerShell as Administrator, then:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or run with bypass flag:
powershell -ExecutionPolicy Bypass -File .\ps\Users\Manage-LargeUserFiles.ps1
```

---

### Issue: D: Drive Not Found

**Error:**
```
Target drive D: does not exist
```

**Solution:**
- Ensure you have a D: drive on your system
- If using external drive, make sure it's connected
- Alternatively, modify scripts to use different target drive (E:, F:, etc.)

---

### Issue: File Locked / Access Denied

**Error:**
```
Failed to copy file: Access denied
```

**Solution:**
- Close programs using the file (Teams, media players, etc.)
- Run PowerShell as Administrator
- Ensure you have write permissions to D: drive

---

### Issue: Hash Verification Failed

**Error:**
```
Hash mismatch - keeping original file
```

**What it means:** Copy was corrupted, original file preserved

**Solution:**
- Check D: drive for errors (run `chkdsk D: /F`)
- Ensure stable connection if D: is external drive
- Try again - file was NOT deleted from C:

---

## 📊 Understanding Reports and Logs

### Scan Report (`LargeUserFiles_[timestamp].txt`)
- Lists all files meeting size threshold
- Shows file path, size, and last modified date
- Summary statistics (total files, total size, scan duration)
- Use this to plan your migration

### Migration Log (`MoveLog_[timestamp].txt`)
- Detailed operation log
- Records every copy, verification, and deletion
- Includes SHA256 hashes for verification
- Keep this for audit trail

---

## 🎓 Best Practices

### Before Migration
1. ✅ Run scan-only first to see what will be moved
2. ✅ Check D: drive has enough free space
3. ✅ Close programs that might have files open
4. ✅ Consider backing up important files (just in case)

### During Migration
1. ✅ Don't interrupt the process
2. ✅ Monitor for errors in console output
3. ✅ Watch disk space on both drives

### After Migration
1. ✅ Review the migration log for any errors
2. ✅ Test accessing a few migrated files
3. ✅ Keep the log file for your records
4. ✅ Update shortcuts/bookmarks to point to D: drive locations

---

## ❓ FAQ

**Q: Will this break my programs?**
A: No. The tool only moves your personal files (documents, videos, etc.), never program files or settings.

**Q: Can I undo a migration?**
A: Yes, just run the tool in reverse (scan D:, move to C:), or manually copy files back.

**Q: What if my computer crashes during migration?**
A: Files are copied before deletion, so originals remain until verification succeeds. Worst case: you have duplicates.

**Q: How long does it take?**
A: Depends on file sizes and drive speed. Scanning is fast (<1 min). Migration depends on total size being moved.

**Q: Can I run this on a schedule?**
A: Yes, you can use Windows Task Scheduler with the PowerShell scripts (use parameters to avoid prompts).

**Q: Does it work with external drives?**
A: Yes, as long as they're connected and appear as a drive letter (D:, E:, etc.).

**Q: Will it move files from all users?**
A: Only from the current user's profile unless run as Administrator.

---

## 📞 Support & Contribution

**Found a bug?** Open an issue on GitHub
**Have a feature request?** Submit a pull request
**Need help?** Check the logs and error messages first

**Repository:** https://github.com/kudadonbe/tools

---

## 📜 License

MIT License - Free to use, modify, and distribute

---

## 🏁 Summary

The **Report & File Migration Tool** is your solution for managing disk space:

1. **Scan** - Find large files eating up your C: drive
2. **Review** - See what files are candidates for migration  
3. **Migrate** - Safely move files to D: drive with verification
4. **Verify** - Hash checking ensures data integrity
5. **Free Space** - Reclaim valuable system drive space

**Choose your version:**
- 🖥️ PowerShell Interactive (easiest for Windows users)
- ⌨️ PowerShell Scripts (automation and scripting)
- 🔧 Go Binary (cross-platform, no dependencies)

**Happy file managing! 🎉**
