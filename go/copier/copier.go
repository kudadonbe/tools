package copier

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"sync"
)

// CopyFile copies a single file from source to destination,
// maintaining relative path structure.
// Returns an error if the copy fails.
func CopyFile(sourcePath, destinationPath string, entry *FileEntry) error {
	srcFile, err := os.Open(filepath.Join(sourcePath, entry.Path))
	if err != nil {
		return fmt.Errorf("failed to open source file %s: %w", entry.Path, err)
	}
	defer srcFile.Close()

	destFilePath := filepath.Join(destinationPath, entry.Path)
	destDir := filepath.Dir(destFilePath)

	if err := os.MkdirAll(destDir, 0755); err != nil {
		return fmt.Errorf("failed to create destination directory %s: %w", destDir, err)
	}

	destFile, err := os.Create(destFilePath)
	if err != nil {
		return fmt.Errorf("failed to create destination file %s: %w", destFilePath, err)
	}
	defer destFile.Close()

	if _, err := io.Copy(destFile, srcFile); err != nil {
		return fmt.Errorf("failed to copy content for file %s: %w", entry.Path, err)
	}

	// Optionally, copy file permissions and modification time
	// This can be added later if needed.
	// info, err := srcFile.Stat()
	// if err == nil {
	// 	os.Chmod(destFilePath, info.Mode())
	// 	os.Chtimes(destFilePath, info.ModTime(), info.ModTime())
	// }

	return nil
}

// CopyWorker is a function that performs the actual file copying
// for a given set of files and updates the migration state.
// It uses a channel to signal completion/errors and allows for graceful shutdown.
func CopyWorker(
	state *MigrationState,
	selectedFolders []string,
	stopCh <-chan struct{},
	updateCh chan<- *FileEntry, // Channel to send updated file entries
	wg *sync.WaitGroup,
) {
	defer wg.Done()

	// Create a map for quick lookup of selected folders
	folderMap := make(map[string]bool)
	for _, folder := range selectedFolders {
		folderMap[folder] = true
	}

	for i := range state.Files {
		entry := &state.Files[i]

		// Check if the file belongs to a selected folder
		// And if its status is not already Copied or Skipped
		isTargetFolder := false
		if len(selectedFolders) == 0 { // If no folders explicitly selected, copy all
			isTargetFolder = true
		} else {
			parts := strings.SplitN(entry.Path, string(os.PathSeparator), 2)
			if len(parts) > 0 && parts[0] != "" && folderMap[parts[0]] {
				isTargetFolder = true
			}
		}

		if isTargetFolder && (entry.Status == Pending || entry.Status == Failed) {
			select {
			case <-stopCh:
				// Received stop signal, mark current as pending (or failed if partially copied)
				// For now, simply return. A more robust implementation might save state specifically here.
				fmt.Printf("Worker received stop signal, stopping copy of %s\n", entry.Path)
				entry.Status = Pending // Ensure it's not InProgress if stopped
				updateCh <- entry      // Send final state
				return
			default:
				// Continue with copy
			}

			entry.Status = InProgress // Mark as in progress
			updateCh <- entry         // Send update to TUI

			err := CopyFile(state.Source, state.Destination, entry)
			if err != nil {
				entry.Status = Failed
				entry.Error = err.Error()
				fmt.Printf("Error copying %s: %v\n", entry.Path, err)
			} else {
				entry.Status = Copied
				entry.Error = "" // Clear any previous error
			}
			updateCh <- entry // Send update to TUI
		}
	}
}
