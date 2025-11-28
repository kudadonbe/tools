package main

import (
	"fmt"
	"os"
	"strings"

	"github.com/fatih/color"
	"github.com/manifoldco/promptui"
	"github.com/kudadonbe/tools/userfiles"
)

const (
	AppName    = "LARGE USER FILES MANAGER"
	AppVersion = "1.0.0"
)

func showHeader(title string) {
	color.Cyan("\n" + strings.Repeat("=", 80))
	color.Cyan("  %s", title)
	color.Cyan(strings.Repeat("=", 80) + "\n")
}

func showMenu() int {
	prompt := promptui.Select{
		Label: "What would you like to do?",
		Items: []string{
			"[1] Scan and generate report only",
			"[2] Scan and move files to D: drive",
			"[3] Exit",
		},
	}

	idx, _, err := prompt.Run()
	if err != nil {
		return 3 // Exit on error
	}

	return idx + 1
}

func getMinimumSize() int {
	prompt := promptui.Prompt{
		Label:   "Enter minimum file size in MB (default: 200)",
		Default: "200",
	}

	result, err := prompt.Run()
	if err != nil {
		return 200
	}

	var size int
	if _, err := fmt.Sscanf(result, "%d", &size); err != nil {
		return 200
	}
	return size
}

func main() {
	showHeader(AppName)

	color.White("  This tool helps you manage large files in C:\\Users\n")
	fmt.Println()
	color.Green("  Files that WILL be scanned:")
	color.HiBlack("    * Documents, Downloads, Videos, Pictures, Desktop")
	color.HiBlack("    * Teams meeting recordings")
	color.HiBlack("    * Large media files, ISOs, backups")
	fmt.Println()
	color.Yellow("  Files that will NOT be touched:")
	color.HiBlack("    * AppData (program settings)")
	color.HiBlack("    * Cloud sync folders (OneDrive, Dropbox, etc.)")
	color.HiBlack("    * Development tools and caches")
	fmt.Println()

	choice := showMenu()

	switch choice {
	case 1:
		showHeader("SCAN AND REPORT")
		minSize := getMinimumSize()
		scanner := userfiles.NewScanner(minSize)
		
		color.Yellow("\n  Scanning C:\\Users for files larger than %dMB...", minSize)
		color.HiBlack("  This may take a few minutes...\n")
		
		scanData, err := scanner.Scan()
		if err != nil {
			color.Red("  Error: %v\n", err)
			os.Exit(1)
		}

		if scanData.TotalFiles == 0 {
			color.Yellow("\n  No files found larger than %dMB\n", minSize)
		} else {
			reportPath, err := userfiles.GenerateReport(scanData, minSize)
			if err != nil {
				color.Red("  Error generating report: %v\n", err)
				os.Exit(1)
			}

			fmt.Println()
			color.Green(strings.Repeat("=", 80))
			color.Green("  Report saved to: %s", reportPath)
			color.Green(strings.Repeat("=", 80))
			fmt.Println()
			color.Green("  Found %d large files\n", scanData.TotalFiles)
			color.Cyan("  Review the report: %s\n", reportPath)
		}

	case 2:
		showHeader("SCAN AND MIGRATE")
		minSize := getMinimumSize()
		scanner := userfiles.NewScanner(minSize)
		
		color.Yellow("\n  Scanning C:\\Users for files larger than %dMB...", minSize)
		color.HiBlack("  This may take a few minutes...\n")
		
		scanData, err := scanner.Scan()
		if err != nil {
			color.Red("  Error: %v\n", err)
			os.Exit(1)
		}

		if scanData.TotalFiles == 0 {
			color.Yellow("\n  No files found larger than %dMB\n", minSize)
		} else {
			reportPath, err := userfiles.GenerateReport(scanData, minSize)
			if err != nil {
				color.Red("  Error generating report: %v\n", err)
				os.Exit(1)
			}

			color.Green("\n  Report saved to: %s\n", reportPath)

			// Start migration
			migrator := userfiles.NewMigrator()
			err = migrator.Migrate(scanData)
			if err != nil {
				color.Red("  Migration error: %v\n", err)
				os.Exit(1)
			}
		}

	case 3:
		fmt.Println()
		color.Cyan("  Goodbye!\n")
		os.Exit(0)

	default:
		fmt.Println()
		color.Red("  Invalid choice. Exiting.\n")
		os.Exit(1)
	}

	fmt.Println()
	color.HiBlack("  Press Enter to exit...")
	fmt.Scanln()
}
