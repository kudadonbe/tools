## 🧼 How to Completely Remove WPS Office and Reset a Domain User Profile in Windows

### 🛠 Purpose:
To ensure a full cleanup of WPS Office and reset a domain user’s Windows profile, restoring the system to a fresh, first-login state.

---

### 📍 PART 1: Uninstall WPS Office

#### 1. Uninstall via Settings
- Go to: **Settings > Apps > Installed Apps**
- Search **WPS Office**
- Click **Uninstall**

#### 2. Manually Delete Remaining Program Folders
Remove these if they still exist:
- `C:\Program Files\Kingsoft`
- `C:\Program Files (x86)\Kingsoft`
- `C:\ProgramData\Kingsoft`
- `C:\ProgramData\WPS Office`

#### 3. Clean WPS Registry Entries (System-Wide)
Open **Regedit** (`Win + R` → `regedit`) and delete:
- `HKEY_LOCAL_MACHINE\SOFTWARE\Kingsoft`
- `HKEY_LOCAL_MACHINE\SOFTWARE\WPS Office`
- *(Optional)* `HKEY_CURRENT_USER\Software\Kingsoft` — only needed if not resetting the user profile

---

### 📍 PART 2: Reset the Domain User Profile

#### 1. Log in as a different Administrator

#### 2. Delete User Folder
- Path: `C:\Users\<username>`
- Delete the folder entirely

#### 3. Remove Registry Profile Key
- Go to:
  ```
  HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList
  ```
- Find the SID with `ProfileImagePath` matching the deleted user (e.g., `C:\Users\john.doe`)
- **Right-click the SID key** and **Delete** it

---

### ✅ Result
When the domain user logs in next:
- A fresh profile will be created
- All WPS traces (installed and user-specific) will be gone
- Group Policies and settings will reapply cleanly
