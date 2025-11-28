package copier

import (
	"fmt"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/muesli/reflow/indent"
	"github.com/muesli/reflow/truncate"
	"github.com/muesli/reflow/wordwrap"
)

// Msg for updating the progress bar
type progressMsg *FileEntry

// ProgressModel for the live progress screen
type ProgressModel struct {
	migrationState *MigrationState
	updateCh       <-chan *FileEntry
	stopCh         chan struct{} // To signal worker to stop from UI

	currentFile  string
	currentBytes int64 // Bytes copied for current file (for per-file progress bar)
	totalBytes   int64 // Total bytes of current file

	width  int
	height int
	done   bool

	// Progress tracking
	totalFiles      int
	copiedFiles     int
	failedFiles     int
	skippedFiles    int
	totalDataCopied int64

	// Lipgloss styles
	headerStyle      lipgloss.Style
	statusStyle      lipgloss.Style
	progressBarStyle lipgloss.Style
	fileStyle        lipgloss.Style
	errorStyle       lipgloss.Style
}

// NewProgressModel initializes a new ProgressModel.
func NewProgressModel(state *MigrationState, updateCh <-chan *FileEntry, stopCh chan struct{}) *ProgressModel {
	m := &ProgressModel{
		migrationState: state,
		updateCh:       updateCh,
		stopCh:         stopCh,
		headerStyle: lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("10")).
			PaddingBottom(1),
		statusStyle: lipgloss.NewStyle().
			Foreground(lipgloss.Color("7")),
		progressBarStyle: lipgloss.NewStyle().
			Foreground(lipgloss.Color("8")).
			Background(lipgloss.Color("237")),
		fileStyle: lipgloss.NewStyle().
			Foreground(lipgloss.Color("15")).
			Bold(true),
		errorStyle: lipgloss.NewStyle().
			Foreground(lipgloss.Color("9")).
			Bold(true),
	}

	// Initialize counts from the current state
	m.totalFiles = len(state.Files)
	for _, entry := range state.Files {
		switch entry.Status {
		case Copied:
			m.copiedFiles++
			m.totalDataCopied += entry.Size
		case Failed:
			m.failedFiles++
		case Skipped:
			m.skippedFiles++
		}
	}
	return m
}

// Init initializes the Progress UI.
func (m ProgressModel) Init() tea.Cmd {
	return m.processUpdates() // Start processing updates from the worker
}

// processUpdates is a command that listens for updates from the copy worker.
func (m ProgressModel) processUpdates() tea.Cmd {
	return func() tea.Msg {
		for {
			select {
			case entry, ok := <-m.updateCh:
				if !ok {
					return nil // Channel closed, worker finished
				}
				return progressMsg(entry)
			case <-m.stopCh:
				return nil // UI stopped, stop processing updates
			}
		}
	}
}

// Update handles messages and updates the ProgressModel.
func (m ProgressModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.Type {
		case tea.KeyCtrlC, tea.KeyEsc:
			close(m.stopCh) // Signal the worker to stop
			m.done = true
			return m, tea.Quit
		}

	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height

	case progressMsg:
		entry := (*FileEntry)(msg)
		// Update model based on entry status
		switch entry.Status {
		case Copied:
			m.copiedFiles++
			m.currentFile = "" // Clear current file
			m.totalDataCopied += entry.Size
		case Failed:
			m.failedFiles++
			m.currentFile = "" // Clear current file
		case Skipped:
			m.skippedFiles++
			m.currentFile = "" // Clear current file
		case InProgress:
			m.currentFile = entry.Path
			m.totalBytes = entry.Size
			m.currentBytes = 0 // Reset for per-file progress (needs byte updates from copier.go)
		}

		// Re-process updates
		return m, m.processUpdates()
	}

	return m, nil
}

// View renders the Progress UI.
func (m ProgressModel) View() string {
	if m.done {
		return "Exiting progress view...\n"
	}

	var s strings.Builder

	s.WriteString(m.headerStyle.Render("File Migration Progress"))
	s.WriteString("\n")

	// Summary
	s.WriteString(m.statusStyle.Render(fmt.Sprintf("Source: %s\n", m.migrationState.Source)))
	s.WriteString(m.statusStyle.Render(fmt.Sprintf("Destination: %s\n", m.migrationState.Destination)))
	s.WriteString("\n")

	// Overall Progress
	completed := m.copiedFiles + m.failedFiles + m.skippedFiles
	var progress float64
	if m.totalFiles > 0 {
		progress = float64(completed) / float64(m.totalFiles)
	}
	progressBar := renderProgressBar(progress, m.width-4, m.progressBarStyle)

	s.WriteString(m.statusStyle.Render(fmt.Sprintf("Total Files: %d, Copied: %d, Failed: %d, Skipped: %d\n",
		m.totalFiles, m.copiedFiles, m.failedFiles, m.skippedFiles)))
	s.WriteString(m.statusStyle.Render(fmt.Sprintf("Progress: %.2f%%\n", progress*100)))
	s.WriteString(progressBar + "\n")

	// Current file progress
	if m.currentFile != "" {
		truncateWidth := m.width - 4
		if truncateWidth < 10 {
			truncateWidth = 10
		}
		s.WriteString(m.fileStyle.Render(fmt.Sprintf("\nCopying: %s\n", truncate.StringWithTail(m.currentFile, uint(truncateWidth), "..."))))
		// For per-file progress, we would need byte-level updates from CopyFile
		// For now, just indicate it's in progress.
	}

	s.WriteString(m.statusStyle.Render(fmt.Sprintf("\nTotal Data Copied: %s", formatBytes(m.totalDataCopied))))

	if m.currentFile == "" && (m.copiedFiles+m.failedFiles+m.skippedFiles == m.totalFiles) && m.totalFiles > 0 {
		s.WriteString(m.headerStyle.Render("\n\nMigration Complete! Press Esc to return to main menu."))
	} else if m.currentFile == "" && m.totalFiles == 0 {
		s.WriteString(m.headerStyle.Render("\n\nNo files to migrate. Press Esc to return to main menu."))
	} else {
		s.WriteString(m.statusStyle.Render("\n\n(Press Ctrl+C or Esc to pause and return to main menu)"))
	}

	// Apply dialog box styling
	wrapWidth := m.width - 4
	if wrapWidth <= 0 {
		wrapWidth = 20
	}
	return dialogBoxStyle.Render(wordwrap.String(indent.String(s.String(), 2), wrapWidth))
}

// renderProgressBar renders a text-based progress bar.
func renderProgressBar(progress float64, width int, style lipgloss.Style) string {
	if width <= 0 {
		return ""
	}
	filledWidth := int(float64(width) * progress)
	if filledWidth > width { // Ensure it doesn't exceed width
		filledWidth = width
	}
	emptyWidth := width - filledWidth

	filled := strings.Repeat("━", filledWidth)
	empty := strings.Repeat(" ", emptyWidth)

	return style.Render(filled) + empty
}
