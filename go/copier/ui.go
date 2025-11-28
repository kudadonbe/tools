package copier

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// Define styles
var (
	focusedStyle   = lipgloss.NewStyle().Foreground(lipgloss.Color("205"))
	blurredStyle   = lipgloss.NewStyle().Foreground(lipgloss.Color("240"))
	cursorStyle    = focusedStyle
	noStyle        = lipgloss.NewStyle()
	dialogBoxStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(lipgloss.Color("62")).
			Padding(1, 2).
			BorderLeft(true).
			BorderRight(true).
			BorderTop(true).
			BorderBottom(true)
)

// State for the TUI
type UIState int

const (
	SelectSource UIState = iota
	ConfirmSource
	SelectDestination
	ConfirmDestination
	ConfirmResume
	FinalizePaths // New state to indicate that paths are selected and UI can quit
)

// Model for the TUI
type UIModel struct {
	state          UIState
	sourcePath     string
	destPath       string
	resumeChoice   bool // true for yes, false for no
	sourcePreview  string
	destPreview    string
	currentInput   string
	inputCursorPos int
	inputErr       error
	width          int
	height         int
	done           bool            // True when the TUI interaction is complete
	initialState   *MigrationState // Loaded if resuming
}

// NewUIModel initializes a new UIModel.
func NewUIModel() *UIModel {
	return &UIModel{
		state:        SelectSource,
		currentInput: "",
	}
}

// Init initializes the UI.
func (m *UIModel) Init() tea.Cmd {
	return tea.EnterAltScreen
}

// Update handles messages and updates the UIModel.
func (m *UIModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch typed := msg.(type) {
	case tea.KeyMsg:
		switch typed.Type {
		case tea.KeyCtrlC, tea.KeyEsc:
			m.done = true
			return m, tea.Quit

		case tea.KeyLeft, tea.KeyRight, tea.KeyHome, tea.KeyEnd:
			if m.state == SelectSource || m.state == SelectDestination {
				switch typed.Type {
				case tea.KeyLeft:
					if m.inputCursorPos > 0 {
						m.inputCursorPos--
					}
				case tea.KeyRight:
					if m.inputCursorPos < len(m.currentInput) {
						m.inputCursorPos++
					}
				case tea.KeyHome:
					m.inputCursorPos = 0
				case tea.KeyEnd:
					m.inputCursorPos = len(m.currentInput)
				}
			}

		case tea.KeyBackspace:
			if m.state == SelectSource || m.state == SelectDestination {
				if m.inputCursorPos > 0 && len(m.currentInput) > 0 {
					m.currentInput = m.currentInput[:m.inputCursorPos-1] + m.currentInput[m.inputCursorPos:]
					m.inputCursorPos--
				}
			}

		case tea.KeyDelete:
			if m.state == SelectSource || m.state == SelectDestination {
				if m.inputCursorPos < len(m.currentInput) {
					m.currentInput = m.currentInput[:m.inputCursorPos] + m.currentInput[m.inputCursorPos+1:]
				}
			}

		case tea.KeyRunes:
			switch m.state {
			case SelectSource, SelectDestination:
				m.currentInput = m.currentInput[:m.inputCursorPos] + string(typed.Runes) + m.currentInput[m.inputCursorPos:]
				m.inputCursorPos += len(typed.Runes)
			case ConfirmSource:
				switch strings.ToLower(string(typed.Runes)) {
				case "y":
					m.state = SelectDestination
					m.currentInput = ""
					m.inputCursorPos = 0
				case "n":
					m.state = SelectSource
					m.sourcePath = ""
					m.sourcePreview = ""
					m.currentInput = ""
					m.inputCursorPos = 0
				}
			case ConfirmDestination:
				switch strings.ToLower(string(typed.Runes)) {
				case "y":
					existingState, err := LoadState(m.destPath)
					if err != nil && !os.IsNotExist(err) {
						m.inputErr = fmt.Errorf("error checking for existing state: %w", err)
						m.state = SelectDestination
						return m, nil
					}
					if existingState != nil {
						m.initialState = existingState
						m.state = ConfirmResume
					} else {
						m.state = FinalizePaths
						return m, tea.Quit
					}
				case "n":
					m.state = SelectDestination
					m.destPath = ""
					m.destPreview = ""
					m.currentInput = ""
					m.inputCursorPos = 0
				}
			case ConfirmResume:
				switch strings.ToLower(string(typed.Runes)) {
				case "y":
					m.resumeChoice = true
					m.state = FinalizePaths
					return m, tea.Quit
				case "n":
					m.resumeChoice = false
					m.state = FinalizePaths
					return m, tea.Quit
				}
			}

		case tea.KeyEnter:
			if m.state == SelectSource {
				path, err := filepath.Abs(m.currentInput)
				if err != nil {
					m.inputErr = fmt.Errorf("invalid path: %w", err)
					return m, nil
				}
				if _, err := os.Stat(path); os.IsNotExist(err) {
					m.inputErr = fmt.Errorf("source directory does not exist: %s", path)
					return m, nil
				}
				m.sourcePath = path
				m.sourcePreview = buildDirPreview(path)
				m.currentInput = ""
				m.inputCursorPos = 0
				m.inputErr = nil
				m.state = ConfirmSource
			} else if m.state == SelectDestination {
				path, err := filepath.Abs(m.currentInput)
				if err != nil {
					m.inputErr = fmt.Errorf("invalid path: %w", err)
					return m, nil
				}
				m.destPath = path
				m.destPreview = buildDirPreview(path)
				m.currentInput = ""
				m.inputCursorPos = 0
				m.inputErr = nil
				m.state = ConfirmDestination
			}
		}

	case tea.WindowSizeMsg:
		m.width = typed.Width
		m.height = typed.Height
	}

	return m, nil
}

// View renders the TUI.
func (m *UIModel) View() string {
	if m.done {
		return "Exiting...\n"
	}

	var s string
	switch m.state {
	case SelectSource:
		s = "Enter Source Directory Path:\n"
	case ConfirmSource:
		s = fmt.Sprintf("Source: %s\n\nContents:\n%s\nConfirm source directory? (y/n)\n", m.sourcePath, m.sourcePreview)
		return dialogBoxStyle.Render(s)
	case SelectDestination:
		s = "Enter Destination Directory Path:\n"
	case ConfirmDestination:
		s = fmt.Sprintf("Destination: %s\n\nContents:\n%s\nConfirm destination directory? (y/n)\n", m.destPath, m.destPreview)
		return dialogBoxStyle.Render(s)
	case ConfirmResume:
		s = fmt.Sprintf("Source: %s\nDestination: %s\n\nAn existing migration state was found. Do you want to resume? (y/n)\n", m.sourcePath, m.destPath)
		return dialogBoxStyle.Render(s)
	case FinalizePaths:
		return "" // Should quit immediately
	}

	inputStyled := noStyle.Render(m.currentInput)
	if m.state == SelectSource || m.state == SelectDestination {
		if m.inputCursorPos > len(inputStyled) {
			m.inputCursorPos = len(inputStyled)
		}
		inputStyled = inputStyled[:m.inputCursorPos] + cursorStyle.Render("|") + inputStyled[m.inputCursorPos:]
	}

	s += fmt.Sprintf("> %s\n", inputStyled)
	if m.inputErr != nil {
		s += fmt.Sprintf("\n%s\n", lipgloss.NewStyle().Foreground(lipgloss.Color("9")).Render(m.inputErr.Error()))
	}

	s += "\n(Press Esc to quit)"
	return dialogBoxStyle.Render(s)
}

func buildDirPreview(path string) string {
	entries, err := os.ReadDir(path)
	if err != nil {
		return fmt.Sprintf("Unable to read directory: %v", err)
	}
	if len(entries) == 0 {
		return "(empty directory)"
	}
	limit := 5
	var b strings.Builder
	for i := 0; i < len(entries) && i < limit; i++ {
		name := entries[i].Name()
		if entries[i].IsDir() {
			name += "/"
		}
		fmt.Fprintf(&b, "- %s\n", name)
	}
	if len(entries) > limit {
		fmt.Fprintf(&b, "... (%d more)\n", len(entries)-limit)
	}
	return b.String()
}

// RunUI starts the TUI and returns the selected source and destination paths,
// the resume choice, and the loaded initial state.
func RunUI() (source, destination string, resume bool, initialState *MigrationState, err error) {
	model := NewUIModel()
	p := tea.NewProgram(model)
	tm, err := p.Run()
	if err != nil {
		return "", "", false, nil, fmt.Errorf("error running UI: %w", err)
	}

	m := tm.(*UIModel)
	if m.done && (m.sourcePath == "" || m.destPath == "") {
		return "", "", false, nil, fmt.Errorf("UI quit without completing path selection")
	}

	return m.sourcePath, m.destPath, m.resumeChoice, m.initialState, nil
}
