package main

import (
	"fmt"
	"log"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"

	tea "github.com/charmbracelet/bubbletea" // Import for Bubble Tea program

	"copier"
)

func main() {
	// Phase 1: Source, Destination, Resume selection
	sourcePath, destPath, resume, initialLoadedState, err := copier.RunUI()
	if err != nil {
		if err.Error() == "UI quit without completing path selection" {
			fmt.Println("User quit path selection. Exiting.")
			os.Exit(0)
		}
		log.Fatalf("Error running initial UI: %v", err)
	}

	var migrationState *copier.MigrationState

	if resume {
		fmt.Printf("Resuming migration from %s to %s.\n", sourcePath, destPath)
		migrationState = initialLoadedState
		// Ensure StartTime is set if resuming an old state that didn't have it (e.g., first run)
		if migrationState.StartTime.IsZero() {
			migrationState.StartTime = time.Now()
		}
	} else {
		fmt.Printf("Starting new migration from %s to %s.\n", sourcePath, destPath)
		fmt.Println("Scanning source directory for files...")
		migrationState, err = copier.ScanSource(sourcePath, destPath)
		if err != nil {
			log.Fatalf("Error scanning source: %v", err)
		}
		migrationState.StartTime = time.Now() // Set start time for new migration
		fmt.Printf("Found %d files to migrate.\n", len(migrationState.Files))
	}

	// Save the state after initial scan or loading, before proceeding to main menu
	err = copier.SaveState(migrationState)
	if err != nil {
		log.Fatalf("Error saving state after initial phase: %v", err)
	}

	// Loop for main menu to allow multiple actions (e.g., copy some folders, then report, then copy more)
	for {
		// Phase 2: Main Menu, Folder Selection
		chosenAction, selectedFolders, err := copier.RunMainMenuUI(migrationState)
		if err != nil {
			// This error message needs to be generalized
			log.Fatalf("Error running main menu UI: %v", err)
		}

		switch chosenAction {
		case "Start Copying Selected Folders":
			fmt.Printf("Starting copy for selected folders: %v\n", selectedFolders)

			// Setup for CopyWorker
			var wg sync.WaitGroup
			stopCh := make(chan struct{})
			updateCh := make(chan *copier.FileEntry, 100) // Buffered channel for updates

			// Signal handling for graceful shutdown (specific to this copy run)
			sigCh := make(chan os.Signal, 1)
			signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM) // Catch Ctrl+C and other termination signals

			// Goroutine to handle external signals
			go func() {
				<-sigCh // Block until a signal is received
				fmt.Println("\nReceived interrupt signal. Attempting graceful shutdown...")
				close(stopCh) // Signal the worker to stop
			}()

			wg.Add(1)
			go copier.CopyWorker(migrationState, selectedFolders, stopCh, updateCh, &wg)

			// Goroutine to process updates and periodically save state
			go func() {
				ticker := time.NewTicker(5 * time.Second) // Save state every 5 seconds
				defer ticker.Stop()
				lastSaveTime := time.Now()

				for {
					select {
					case entry, ok := <-updateCh:
						if !ok { // Channel closed, worker finished
							fmt.Println("Copy worker finished.")
							return
						}
						// Update the corresponding file entry in migrationState
						for i := range migrationState.Files {
							if migrationState.Files[i].Path == entry.Path {
								migrationState.Files[i] = *entry
								break
							}
						}
						if time.Since(lastSaveTime) > 5*time.Second {
							if err := copier.SaveState(migrationState); err != nil {
								log.Printf("Warning: error saving state periodically: %v", err)
							}
							lastSaveTime = time.Now()
						}

					case <-ticker.C:
						// Periodic save, even if no updates
						if err := copier.SaveState(migrationState); err != nil {
							log.Printf("Warning: error saving state periodically: %v", err)
						}
						lastSaveTime = time.Now()
					case <-stopCh: // If main goroutine also gets stop signal directly
						fmt.Println("Main loop received stop signal. Stopping updates.")
						return
					}
				}
			}()

			// Launch the progress TUI
			p := tea.NewProgram(copier.NewProgressModel(migrationState, updateCh, stopCh))
			if _, err := p.Run(); err != nil {
				log.Fatalf("Error running progress UI: %v", err)
			}

			wg.Wait()       // Wait for the CopyWorker to finish
			close(updateCh) // Close update channel once worker is done

			// After copying, save the state (final save before potentially returning to main menu)
			if err := copier.SaveState(migrationState); err != nil {
				log.Fatalf("Error saving state after copy process: %v", err)
			}
			fmt.Printf("\nCopy process completed or interrupted. Final state saved to %s\n", copier.GetStateFilePath(destPath))

		case "Generate Overall Report":
			fmt.Println("Generating overall report...")
			if err := copier.GenerateMainReport(migrationState, "."); err != nil {
				log.Fatalf("Error generating main report: %v", err)
			}
			fmt.Printf("Main report generated in .\n")
		case "Quit":
			fmt.Println("Exiting application.")
			goto endProgram
		default: // User quit via Ctrl+C or Esc during main menu
			fmt.Println("User quit main menu. Exiting.")
			goto endProgram
		}
	}

endProgram:
	// Final save of the state (useful if folders were marked as copied/failed/skipped)
	// This ensures the last updates are persisted.
	err = copier.SaveState(migrationState)
	if err != nil {
		log.Fatalf("Error saving final state: %v", err)
	}
	fmt.Printf("Final state saved to %s\n", copier.GetStateFilePath(destPath))

	fmt.Println("\nMigration process finished (or user quit).")
}
