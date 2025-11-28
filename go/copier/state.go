package copier

import (
	"encoding/json"
	"io/ioutil"
	"os"
	"path/filepath"
	"time"
)

const stateFileName = ".migration.state.json"

// FileStatus represents the copy status of a single file.
type FileStatus string

const (
	Pending    FileStatus = "pending"
	InProgress FileStatus = "in_progress"
	Copied     FileStatus = "copied"
	Skipped    FileStatus = "skipped"
	Failed     FileStatus = "failed"
)

// FileEntry represents the state of a single file in the migration.
type FileEntry struct {
	Path         string     `json:"path"`
	Size         int64      `json:"size"`
	ModifiedTime time.Time  `json:"modifiedTime"`
	Status       FileStatus `json:"status"`
	Error        string     `json:"error,omitempty"`
}

// MigrationState represents the entire state of the migration process.
type MigrationState struct {
	Source      string      `json:"source"`
	Destination string      `json:"destination"`
	Files       []FileEntry `json:"files"`
	StartTime   time.Time   `json:"startTime"`
	EndTime     time.Time   `json:"endTime"`
}

// GetStateFilePath returns the full path to the state file for a given destination.
func GetStateFilePath(destination string) string {
	return filepath.Join(destination, stateFileName)
}

// LoadState reads the migration state from a JSON file.
// If the file does not exist, it returns os.ErrNotExist.
func LoadState(destination string) (*MigrationState, error) {
	stateFilePath := GetStateFilePath(destination)
	data, err := ioutil.ReadFile(stateFilePath)
	if err != nil {
		return nil, err
	}

	state := &MigrationState{}
	err = json.Unmarshal(data, state)
	if err != nil {
		return nil, err
	}
	return state, nil
}

// SaveState writes the migration state to a JSON file.
func SaveState(state *MigrationState) error {
	stateFilePath := GetStateFilePath(state.Destination)
	data, err := json.MarshalIndent(state, "", "  ")
	if err != nil {
		return err
	}

	// Ensure the destination directory exists before writing the state file
	if err := os.MkdirAll(state.Destination, 0755); err != nil {
		return err
	}

	return ioutil.WriteFile(stateFilePath, data, 0644)
}
