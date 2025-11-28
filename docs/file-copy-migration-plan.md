# File Copy and Migration Tool Plan (Upgraded)

## 1. Goal
To create a resilient, Go-based migration manager for efficiently copying large numbers of files. The tool will feature a user-friendly Text-based User Interface (TUI) that allows for pausing and resuming, interactive batching of folders, and real-time progress monitoring, while generating comprehensive reports.

## 2. Workflow & TUI - Interactive and Flexible

### Phase 1: Setup & Resume
1.  The user starts the tool.
2.  The TUI prompts for `source` and `destination` directory selection using an interactive file picker.
3.  The tool checks for a `.migration.state.json` file in the destination's root. If found, it asks the user if they wish to **resume the previous session**.

### Phase 2: Interactive Folder Selection (Main Menu)
1.  The tool scans the source directory (or loads from the state file) and presents a TUI with a multi-select list of all top-level folders.
2.  The user can select any number of folders to process in a batch. Folders already completed are marked as such.
3.  The main menu provides options: `[Start Copying Selected Folders]`, `[Generate Overall Report]`, and `[Quit]`.

### Phase 3: Controlled Copying (with Pause)
1.  When copying begins, a live progress screen is displayed.
2.  The user can press `Ctrl+C` at any time to **gracefully pause** the operation. The tool will immediately save its current state and exit cleanly.

### Phase 4: Loop and Continue
1.  After a batch of folders is copied, the TUI returns to the folder selection screen.
2.  The user can then select more folders for the next batch, generate an updated report, or exit. This provides the flexibility to "copy more main folders" on command.

## 3. State Management for Pause & Resume
*   A state file, `.migration.state.json`, will be maintained in the `destination` directory.
*   This file is the "memory" of the migration, containing a list of every file from the source and its status (`pending`, `in_progress`, `copied`, `skipped`, `failed`), size, and modification time. This allows for robust tracking and resuming.

## 4. File Copying Logic
*   **Recursive Copy**: The tool recursively traverses the `source` directory.
*   **Efficient Binary Copying**: Utilizes Go's `io.Copy` for high-performance file transfer.
*   **State-based Skip**: Instead of just checking for file existence, the tool will rely on the state file. It will only copy files marked as `pending`.

## 5. Reporting
*   **Main Report**: A comprehensive report (`migration-report-YYYYMMDD-HHMMSS.md`) can be generated on demand from the main menu, summarizing the current state of the entire migration.
*   **Individual Folder Reports**: Smaller reports (`_migration_report.md`) will be created inside each completed destination folder.
*   The report content will follow the improved template format.

## 6. Technology Stack
*   **Language**: Go
*   **TUI Library**: `Bubble Tea` for the rich, interactive user interface.
*   **State Management**: Standard Go JSON library for handling the state file.