package userfiles

import (
	"crypto/sha256"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"

	"github.com/fatih/color"
)

// ExcludeFolders contains system and program folders to skip
var ExcludeFolders = []string{
	// Application data
	"AppData", "Application Data", "Local Settings",
	
	// Development tools
	".nuget", ".vscode", ".android", ".gradle", ".docker", ".m2", ".npm",
	".cargo", "node_modules", "venv", "env", ".virtualenv",
	
	// Cloud sync
	"OneDrive", "Dropbox", "Google Drive", "iCloudDrive",
	
	// Windows system
	"Saved Games", "Searches", "Links", "Contacts", "Favorites",
	"Cookies", "NetHood", "PrintHood", "Recent", "SendTo",
	"Start Menu", "Templates",
	
	// Browser profiles
	".mozilla", ".chrome", "Chrome", "Firefox", "Edge",
	
	// Security sensitive
	".ssh", ".gnupg", ".aws", ".kube",
	
	// IDE settings
	"workspace", ".idea", ".eclipse",
	
	// Game launchers
	"Steam", "Epic Games", "Battle.net",
	
	// Cache
	"Temp", "tmp", "cache", "Cache",
}

// FileInfo represents a large file found during scan
type FileInfo struct {
	Path     string
	FullPath string
	SizeMB   float64
}

// ScanData holds the results of a scan operation
type ScanData struct {
	Results    map[string][]FileInfo
	TotalFiles int
}

// Scanner scans for large files
type Scanner struct {
	MinSizeMB int64
}

// NewScanner creates a new scanner instance
func NewScanner(minSizeMB int) *Scanner {
	return &Scanner{
		MinSizeMB: int64(minSizeMB),
	}
}

// isExcluded checks if a path contains any excluded folders
func isExcluded(path string) bool {
	for _, exclude := range ExcludeFolders {
		pattern := fmt.Sprintf(`\\%s\\`, regexp.QuoteMeta(exclude))
		matched, _ := regexp.MatchString(pattern, path)
		if matched {
			return true
		}
	}
	return false
}

// Scan performs the file scan operation
func (s *Scanner) Scan() (*ScanData, error) {
	results := make(map[string][]FileInfo)
	totalFiles := 0

	usersPath := `C:\Users`
	userDirs, err := os.ReadDir(usersPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read users directory: %w", err)
	}

	skipDirs := map[string]bool{
		"Public": true, "Default": true, "Default User": true, "All Users": true,
	}

	for _, userDir := range userDirs {
		if !userDir.IsDir() || skipDirs[userDir.Name()] {
			continue
		}

		color.Cyan("  Scanning: %s...", userDir.Name())

		userPath := filepath.Join(usersPath, userDir.Name())
		var userFiles []FileInfo

		err := filepath.Walk(userPath, func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return nil // Skip files we can't access
			}

			// Skip directories
			if info.IsDir() {
				return nil
			}

			// Check size
			if info.Size() < s.MinSizeMB*1024*1024 {
				return nil
			}

			// Check exclusions
			if isExcluded(path) {
				return nil
			}

			// Add file
			relativePath := strings.Replace(path, userPath, "~", 1)
			relativePath = strings.ReplaceAll(relativePath, "\\", "/")

			userFiles = append(userFiles, FileInfo{
				Path:     relativePath,
				FullPath: path,
				SizeMB:   float64(info.Size()) / (1024 * 1024),
			})
			totalFiles++

			return nil
		})

		if err != nil {
			color.Yellow("  Warning: Error scanning %s: %v", userDir.Name(), err)
		}

		if len(userFiles) > 0 {
			results[userDir.Name()] = userFiles
		}
	}

	return &ScanData{
		Results:    results,
		TotalFiles: totalFiles,
	}, nil
}

// GenerateReport creates a text report from scan data
func GenerateReport(data *ScanData, minSizeMB int) (string, error) {
	timestamp := time.Now().Format("20060102_150405")
	reportPath := fmt.Sprintf("LargeUserFiles_%s.txt", timestamp)

	file, err := os.Create(reportPath)
	if err != nil {
		return "", fmt.Errorf("failed to create report: %w", err)
	}
	defer file.Close()

	// Write header
	fmt.Fprintf(file, "%s\n", strings.Repeat("=", 80))
	fmt.Fprintf(file, "LARGE FILES REPORT (Files > %dMB)\n", minSizeMB)
	fmt.Fprintf(file, "Generated: %s\n", time.Now().Format("2006-01-02 15:04:05"))
	fmt.Fprintf(file, "Total files found: %d\n", data.TotalFiles)
	fmt.Fprintf(file, "%s\n\n", strings.Repeat("=", 80))

	// Write user sections
	for user, files := range data.Results {
		fmt.Fprintf(file, "\n%s (Users/%s)\n", user, user)
		fmt.Fprintf(file, "%s\n", strings.Repeat("-", 80))

		totalSize := 0.0
		for _, f := range files {
			fmt.Fprintf(file, "%-70s | %.2f MB\n", f.Path, f.SizeMB)
			totalSize += f.SizeMB
		}

		fmt.Fprintf(file, "\nSubtotal: %d files, %.2f MB\n\n", len(files), totalSize)
	}

	return reportPath, nil
}

// calculateHash computes SHA256 hash of a file
func calculateHash(filePath string) (string, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return "", err
	}
	defer file.Close()

	hash := sha256.New()
	if _, err := io.Copy(hash, file); err != nil {
		return "", err
	}

	return fmt.Sprintf("%x", hash.Sum(nil)), nil
}

// copyFileWithVerification copies a file and verifies integrity
func copyFileWithVerification(src, dst string) error {
	// Create destination directory
	dstDir := filepath.Dir(dst)
	if err := os.MkdirAll(dstDir, 0755); err != nil {
		return fmt.Errorf("failed to create directory: %w", err)
	}

	// Copy file
	srcFile, err := os.Open(src)
	if err != nil {
		return err
	}
	defer srcFile.Close()

	dstFile, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer dstFile.Close()

	if _, err := io.Copy(dstFile, srcFile); err != nil {
		return err
	}

	// Verify with hash
	srcHash, err := calculateHash(src)
	if err != nil {
		return fmt.Errorf("failed to hash source: %w", err)
	}

	dstHash, err := calculateHash(dst)
	if err != nil {
		return fmt.Errorf("failed to hash destination: %w", err)
	}

	if srcHash != dstHash {
		os.Remove(dst)
		return fmt.Errorf("hash mismatch")
	}

	return nil
}

// Migrator handles file migration
type Migrator struct {
	LogPath string
}

// NewMigrator creates a new migrator
func NewMigrator() *Migrator {
	timestamp := time.Now().Format("20060102_150405")
	return &Migrator{
		LogPath: fmt.Sprintf("MoveLog_%s.txt", timestamp),
	}
}

// writeLog writes to the migration log
func (m *Migrator) writeLog(level, message string) {
	logFile, err := os.OpenFile(m.LogPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return
	}
	defer logFile.Close()

	timestamp := time.Now().Format("2006-01-02 15:04:05")
	fmt.Fprintf(logFile, "[%s] [%s] %s\n", timestamp, level, message)
}

// Migrate performs the migration to D: drive
func (m *Migrator) Migrate(data *ScanData) error {
	fmt.Println()
	color.Yellow(strings.Repeat("=", 80))
	color.Yellow("  MIGRATION TO D: DRIVE")
	color.Yellow(strings.Repeat("=", 80))
	fmt.Println()

	// Check D: exists
	if _, err := os.Stat(`D:\`); os.IsNotExist(err) {
		return fmt.Errorf("D: drive not found")
	}

	color.Yellow("  Found %d files to migrate\n", data.TotalFiles)
	fmt.Println("  Files will be:")
	color.HiBlack("    1. Copied to D:\\Users\\<username>\\...")
	color.HiBlack("    2. Verified using SHA256 hash")
	color.HiBlack("    3. Deleted from C: only if verification succeeds")
	fmt.Println()

	// Confirm
	fmt.Print("  Proceed with migration? (Y/N): ")
	var confirm string
	fmt.Scanln(&confirm)
	if confirm != "Y" && confirm != "y" {
		color.Yellow("  Migration cancelled.\n")
		return nil
	}

	m.writeLog("INFO", "Starting migration to D: drive")

	stats := struct {
		TotalFiles      int
		CopiedFiles     int
		DeletedFiles    int
		FailedFiles     int
		TotalBytesMoved int64
	}{}

	fmt.Println()
	color.Cyan("  Starting migration...\n")

	for user, files := range data.Results {
		color.Cyan("  Processing: %s", user)

		for _, file := range files {
			stats.TotalFiles++

			relativePath := strings.Replace(file.FullPath, `C:\Users\`, "", 1)
			destPath := filepath.Join(`D:\Users`, relativePath)

			color.HiBlack("    Processing: %s (%.2f MB)", file.Path, file.SizeMB)

			// Copy
			color.HiBlack("      -> Copying...")
			err := copyFileWithVerification(file.FullPath, destPath)

			if err == nil {
				color.HiBlack("      -> Verifying...")
				
				// Try to delete
				if err := os.Remove(file.FullPath); err == nil {
					stats.DeletedFiles++
					color.Green("      [OK] Migrated successfully")
					m.writeLog("SUCCESS", fmt.Sprintf("Moved %s to %s (%.2f MB)", file.FullPath, destPath, file.SizeMB))
				} else {
					color.Yellow("      [WARN] Copied but file is locked (kept on C:)")
					m.writeLog("WARNING", fmt.Sprintf("Copied but locked: %s", file.FullPath))
				}

				stats.CopiedFiles++
				stats.TotalBytesMoved += int64(file.SizeMB * 1024 * 1024)
			} else {
				stats.FailedFiles++
				color.Red("      [ERROR] Failed: %v", err)
				m.writeLog("ERROR", fmt.Sprintf("%s - %v", file.FullPath, err))
			}
		}
		fmt.Println()
	}

	// Summary
	fmt.Println()
	color.Green(strings.Repeat("=", 80))
	color.Green("  MIGRATION COMPLETE")
	color.Green(strings.Repeat("=", 80))
	fmt.Println()
	color.White("  Total files found:     %d", stats.TotalFiles)
	color.Green("  Successfully copied:   %d", stats.CopiedFiles)
	color.Green("  Deleted from C:        %d", stats.DeletedFiles)
	color.Red("  Failed:                %d", stats.FailedFiles)
	color.Cyan("  Total data moved:      %.2f GB", float64(stats.TotalBytesMoved)/(1024*1024*1024))
	fmt.Println()
	color.HiBlack("  Log file: %s\n", m.LogPath)

	return nil
}
