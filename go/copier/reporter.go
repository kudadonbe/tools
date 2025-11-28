package copier

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"text/template"
	"time"
)

// ReportData holds all the data needed to populate the main report template.
type ReportData struct {
	ServerName        string
	SourcePath        string
	DestinationPath   string
	MigrationDate     string
	RootFolders       []string
	OverallSummary    ReportSummary
	FolderSummaries   map[string]FolderReportSummary
	FailedFiles       []FileEntry // Details for all failed files
	ReportGenerated   string
	MigrationDuration string
}

// ReportSummary holds summary statistics for the overall migration.
type ReportSummary struct {
	StartTime            time.Time
	EndTime              time.Time
	TotalFiles           int
	SuccessfullyCopied   int
	FilesSkipped         int
	Failed               int
	SuccessRate          string
	TotalDataTransferred string // Human-readable format
	MigrationDuration    string
}

// FolderReportSummary holds summary statistics and files for a specific folder.
type FolderReportSummary struct {
	TotalFiles         int
	SuccessfullyCopied int
	FilesSkipped       int
	Failed             int
	Files              []FileEntry // All files processed in this specific folder
}

// MainReportTemplate is the markdown template for the comprehensive migration report.
const MainReportTemplate = `
# File Server Migration Report

---

## Server Information

**Server Name:** {{.ServerName}}
**Source Path:** {{.SourcePath}}
**Destination Path:** {{.DestinationPath}}
**Migration Date:** {{.MigrationDate}}

---

## Migration Results by Folder
{{range $folderName, $summary := .FolderSummaries}}
### {{ $folderName }} - File List

| File Path | Status | Size | Notes |
|---|---|---|---|
{{range $file := $summary.Files}}
{{if eq $file.Status "Failed"}}
| {{ $file.Path }} | ✗ Can't copy | {{ formatBytes $file.Size }} | {{ $file.Error }} |
{{else if eq $file.Status "Copied"}}
| {{ $file.Path }} | ✓ Copied successfully | {{ formatBytes $file.Size }} | |
{{else if eq $file.Status "Skipped"}}
| {{ $file.Path }} | ✓ Skipped (exists) | {{ formatBytes $file.Size }} | |
{{else}}
| {{ $file.Path }} | - Pending/In Progress | {{ formatBytes $file.Size }} | |
{{end}}
{{end}}
{{end}}

---

## Summary

**Start Time:** {{formatTime .OverallSummary.StartTime}}
**End Time:** {{formatTime .OverallSummary.EndTime}}
**Total Duration:** {{.OverallSummary.MigrationDuration}}

**Total Files:** {{.OverallSummary.TotalFiles}}
**Total Data Transferred:** {{.OverallSummary.TotalDataTransferred}}

**Successfully Copied:** {{.OverallSummary.SuccessfullyCopied}} (✓)
**Files Skipped:** {{.OverallSummary.FilesSkipped}} (✓)
**Failed:** {{.OverallSummary.Failed}} (✗)

**Success Rate:** {{.OverallSummary.SuccessRate}}

---

## Failed Files Details

| File Path | Error Reason | Notes |
|---|---|---|
{{range .FailedFiles}}
| {{.Path}} | {{.Error}} | |
{{end}}

---

**Report Generated:** {{.ReportGenerated}}
`

const FolderReportTemplate = `
# Folder Migration Report: {{.FolderName}}

---

## Summary for {{.FolderName}}

**Total Files:** {{.Summary.TotalFiles}}
**Successfully Copied:** {{.Summary.SuccessfullyCopied}} (✓)
**Files Skipped:** {{.Summary.FilesSkipped}} (✓)
**Failed:** {{.Summary.Failed}} (✗)

---

## File Details for {{.FolderName}}
| File Path | Status | Size | Notes |
|---|---|---|---|
{{range $file := .Files}}
{{if eq $file.Status "Failed"}}
| {{ $file.Path }} | ✗ Can't copy | {{ formatBytes $file.Size }} | {{ $file.Error }} |
{{else if eq $file.Status "Copied"}}
| {{ $file.Path }} | ✓ Copied successfully | {{ formatBytes $file.Size }} | |
{{else if eq $file.Status "Skipped"}}
| {{ $file.Path }} | ✓ Skipped (exists) | {{ formatBytes $file.Size }} | |
{{else}}
| {{ $file.Path }} | - Pending/In Progress | {{ formatBytes $file.Size }} | |
{{end}}
{{end}}
`

// Template for a single folder report
type SingleFolderReportData struct {
	FolderName string
	Summary    FolderReportSummary
	Files      []FileEntry // All files for this folder
}

// Function map for template rendering
var templateFuncs = template.FuncMap{
	"formatBytes": formatBytes,
	"formatTime":  formatTime,
}

// GenerateMainReport generates the comprehensive migration report.
func GenerateMainReport(state *MigrationState, reportDir string) error {
	t, err := template.New("mainReport").Funcs(templateFuncs).Parse(MainReportTemplate)
	if err != nil {
		return fmt.Errorf("error parsing main report template: %w", err)
	}

	reportData, err := prepareMainReportData(state)
	if err != nil {
		return fmt.Errorf("error preparing main report data: %w", err)
	}

	reportFilePath := filepath.Join(reportDir, fmt.Sprintf("migration-report-%s.md", time.Now().Format("20060102-150405")))
	file, err := os.Create(reportFilePath)
	if err != nil {
		return fmt.Errorf("error creating main report file: %w", err)
	}
	defer file.Close()

	if err := t.Execute(file, reportData); err != nil {
		return fmt.Errorf("error executing main report template: %w", err)
	}
	return nil
}

// GenerateFolderReport generates a simplified report for a specific top-level folder.
func GenerateFolderReport(state *MigrationState, folderName string) error {
	t, err := template.New("folderReport").Funcs(templateFuncs).Parse(FolderReportTemplate)
	if err != nil {
		return fmt.Errorf("error parsing folder report template: %w", err)
	}

	folderReportData, err := prepareFolderReportData(state, folderName)
	if err != nil {
		return fmt.Errorf("error preparing folder report data for %s: %w", folderName, err)
	}

	// Ensure the destination folder exists before creating the report file
	destFolderFullPath := filepath.Join(state.Destination, folderName)
	if err := os.MkdirAll(destFolderFullPath, 0755); err != nil {
		return fmt.Errorf("failed to create destination folder for report %s: %w", destFolderFullPath, err)
	}

	reportFilePath := filepath.Join(destFolderFullPath, "_migration_report.md")
	file, err := os.Create(reportFilePath)
	if err != nil {
		return fmt.Errorf("error creating folder report file for %s: %w", folderName, err)
	}
	defer file.Close()

	if err := t.Execute(file, folderReportData); err != nil {
		return fmt.Errorf("error executing folder report template for %s: %w", folderName, err)
	}
	return nil
}

// prepareMainReportData aggregates data for the main report.
func prepareMainReportData(state *MigrationState) (*ReportData, error) {
	data := &ReportData{
		ServerName:      "Unknown", // TODO: Get actual server name
		SourcePath:      state.Source,
		DestinationPath: state.Destination,
		MigrationDate:   time.Now().Format("2006-01-02"),
		FolderSummaries: make(map[string]FolderReportSummary),
		ReportGenerated: time.Now().Format("2006-01-02 15:04:05"),
	}

	var totalFiles, successfullyCopied, filesSkipped, failed int
	var totalDataCopied int64

	rootFoldersMap := make(map[string]struct{})

	// Prepare folder-specific summaries
	folderSummaryMap := make(map[string]*FolderReportSummary)
	for _, file := range state.Files {
		topLevelFolder := strings.SplitN(file.Path, string(os.PathSeparator), 2)[0]
		if _, ok := folderSummaryMap[topLevelFolder]; !ok {
			folderSummaryMap[topLevelFolder] = &FolderReportSummary{}
		}
		folderSummary := folderSummaryMap[topLevelFolder]

		folderSummary.TotalFiles++
		folderSummary.Files = append(folderSummary.Files, file) // Collect all files for the folder
		switch file.Status {
		case Copied:
			folderSummary.SuccessfullyCopied++
			totalDataCopied += file.Size
		case Skipped:
			folderSummary.FilesSkipped++
		case Failed:
			folderSummary.Failed++
			data.FailedFiles = append(data.FailedFiles, file) // Add to overall failed files
		}
		rootFoldersMap[topLevelFolder] = struct{}{}
	}

	for folderName := range rootFoldersMap {
		data.RootFolders = append(data.RootFolders, folderName)
	}
	sort.Strings(data.RootFolders)

	for _, folderName := range data.RootFolders {
		summary := folderSummaryMap[folderName]
		data.FolderSummaries[folderName] = *summary
		totalFiles += summary.TotalFiles
		successfullyCopied += summary.SuccessfullyCopied
		filesSkipped += summary.FilesSkipped
		failed += summary.Failed
	}

	data.OverallSummary = ReportSummary{
		StartTime:            state.StartTime,
		EndTime:              time.Now(), // Report generation time
		TotalFiles:           totalFiles,
		SuccessfullyCopied:   successfullyCopied,
		FilesSkipped:         filesSkipped,
		Failed:               failed,
		TotalDataTransferred: formatBytes(totalDataCopied),
	}

	if totalFiles > 0 {
		data.OverallSummary.SuccessRate = fmt.Sprintf("%.2f%%", float64(successfullyCopied+filesSkipped)/float64(totalFiles)*100)
	} else {
		data.OverallSummary.SuccessRate = "N/A"
	}
	data.OverallSummary.MigrationDuration = formatDuration(data.OverallSummary.EndTime.Sub(data.OverallSummary.StartTime))

	return data, nil
}

// prepareFolderReportData aggregates data for a single folder report.
func prepareFolderReportData(state *MigrationState, folderName string) (*SingleFolderReportData, error) {
	data := &SingleFolderReportData{
		FolderName: folderName,
	}

	for _, file := range state.Files {
		topLevelFolder := strings.SplitN(file.Path, string(os.PathSeparator), 2)[0]
		if topLevelFolder == folderName {
			data.Summary.TotalFiles++
			data.Files = append(data.Files, file) // Collect all files for this folder
			switch file.Status {
			case Copied:
				data.Summary.SuccessfullyCopied++
			case Skipped:
				data.Summary.FilesSkipped++
			case Failed:
				data.Summary.Failed++
			}
		}
	}
	return data, nil
}
