# File Server Migration Report

---

## Server Information

**Server Name:** `<Server Name, e.g., //~102.253/PDC>`
**Source Path:** `<Source Directory Path>`
**Destination Path:** `<Destination Directory Path>`
**Migration Date:** `<YYYY-MM-DD>`

---

## Migration Results by Folder

### `<Folder Name>` - File List

Example:

#### B1 - Directory list

| File Path            | Status                | Size    | Notes |
|----------------------|-----------------------|---------|-------|
| Invoice/123.docx     | ✓ Copied successfully | 1.2 MB  |       |
| Invoice/234.pdf      | ✓ Skipped (exists)    | 500 KB  |       |
| Sharia/20050203.mp3  | ✗ Can't copy          | 3.1 MB  | Permission denied |
| Meeting/Rec/FCM-1674.mp4 | ✗ Can't copy          | 1.2 GB  | File is locked |


---

## Summary

**Start Time:** `<YYYY-MM-DD HH:MM:SS>`
**End Time:** `<YYYY-MM-DD HH:MM:SS>`
**Total Duration:** `<HH:MM:SS>`

**Total Files:** `<number>`
**Total Data Transferred:** `<size GB/MB>`

**Successfully Copied:** `<number>` (✓)
**Files Skipped:** `<number>` (✓)
**Failed:** `<number>` (✗)

**Success Rate:** `<percentage>%`

---

## Failed Files Details

| File Path | Error Reason | Notes |
|-----------|--------------|-------|
| `<path>`  | `<reason>`   | `<any additional notes>` |

---

**Report Generated:** `<YYYY-MM-DD HH:MM:SS>`