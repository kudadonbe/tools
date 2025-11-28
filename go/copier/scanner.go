package copier

import (
	"os"
	"path/filepath"
	"time"
)

// ScanSource walks the source directory and creates an initial MigrationState.
func ScanSource(sourcePath, destinationPath string) (*MigrationState, error) {
	state := &MigrationState{
		Source:      sourcePath,
		Destination: destinationPath,
		Files:       []FileEntry{},
		StartTime:   time.Now(),
	}

	err := filepath.Walk(sourcePath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			// If there's an error accessing a path, we'll log it but try to continue
			// with other paths. For migration, it's critical to capture all potential issues.
			// However, for the initial scan, we might just want to skip problematic paths.
			// For now, return the error to stop the walk on critical errors.
			return err
		}

		if !info.IsDir() {
			relativePath, err := filepath.Rel(sourcePath, path)
			if err != nil {
				return err
			}
			state.Files = append(state.Files, FileEntry{
				Path:         relativePath,
				Size:         info.Size(),
				ModifiedTime: info.ModTime(),
				Status:       Pending,
			})
		}
		return nil
	})

	if err != nil {
		return nil, err
	}

	return state, nil
}
