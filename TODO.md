# TODO - Tools Repository

## 📋 Planned Features

### 🔄 Duplicate File Detection & Management
**Priority:** High  
**Status:** Planned  
**Estimated Effort:** Medium

**Description:**
Add duplicate file detection to both PowerShell and Go implementations.

**Features to Implement:**
- [ ] Scan directories for duplicate files using SHA256 hash
- [ ] Group duplicates by content (not just name)
- [ ] Calculate space wasted by duplicates
- [ ] Generate detailed duplicate report
- [ ] Interactive cleanup options:
  - [ ] Delete duplicates (keep newest/largest/first)
  - [ ] Create hardlinks (save space, keep structure)
  - [ ] Create symbolic links
  - [ ] Move duplicates to archive folder
- [ ] Safety features:
  - [ ] Dry-run/preview mode
  - [ ] Exclude system/critical files
  - [ ] Backup before deletion
  - [ ] Detailed logging

**Implementation Notes:**
- Reuse existing scanning infrastructure
- Add `Find-DuplicateFiles.ps1` to `ps/Users/`
- Add duplicate detection to Go `userfiles` package
- Share exclusion rules with large file scanner
- Consider parallel hashing for performance

**Use Cases:**
1. Free up disk space by removing duplicate downloads
2. Deduplicate backup folders
3. Find duplicate photos/videos across directories
4. Optimize cloud storage usage
5. Clean up after syncing multiple devices

**Example Workflow:**
```
1. Scan → Find 156 duplicates wasting 12.4 GB
2. Review → Group by hash with file locations
3. Choose → Delete/Hardlink/Archive
4. Execute → Safe removal with verification
5. Report → Summary of space saved
```

**Dependencies:**
- None (uses existing codebase)

**Cross-reference:**
- Related to: Large file management tools
- Shares: Scanner, file operations, logging utilities

---

## 🚀 Future Enhancements

### PowerShell
- [ ] Add network drive support
- [ ] Parallel scanning with runspaces
- [ ] GUI option using Windows Forms
- [ ] Integration with Windows Storage Sense

### Go Binary
- [ ] Progress bar for long scans
- [ ] Configuration file support
- [ ] Daemon mode for scheduled scans
- [ ] REST API for remote management

### Python (kdm)
- [ ] Add watermarking to PDFs
- [ ] Batch image processing
- [ ] PDF form filling
- [ ] Digital signatures

---

## 🐛 Known Issues
*None currently*

---

## 📝 Documentation Improvements
- [ ] Add video tutorials
- [ ] Create troubleshooting guide
- [ ] Add FAQ section
- [ ] Performance benchmarks

---

**Last Updated:** 2025-11-26  
**Maintainer:** Hussain Shareef
