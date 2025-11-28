package copier

import (
	"fmt"
	"os"
	"sort"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

var (
	menuCursor        = lipgloss.NewStyle().Foreground(lipgloss.Color("205")).Render("›")
	itemStyle         = lipgloss.NewStyle().Foreground(lipgloss.Color("252"))
	selectedItemStyle = lipgloss.NewStyle().Inherit(itemStyle).Bold(true)
)

// MainMenuState for the main menu TUI
type MainMenuState int

const (
	SelectFolders MainMenuState = iota
	SelectAction
)

// FolderItem represents a top-level folder for selection in the main menu.
type FolderItem struct {
	Name     string
	Selected bool
	Status   FileStatus // To indicate if it's already completed from a previous session
}

// MainMenuModel for the TUI
type MainMenuModel struct {
	state           MainMenuState
	migrationState  *MigrationState // The overall migration state
	folders         []FolderItem
	folderCursor    int // Which folder is currently highlighted
	actionCursor    int // Which main menu action is selected
	mainMenuOptions []string
	width           int
	height          int
	done            bool // True when the TUI interaction is complete

	ChosenAction string // The action chosen by the user (e.g., "Start Copying", "Quit")
}

// NewMainMenuModel initializes a new MainMenuModel.
func NewMainMenuModel(state *MigrationState) *MainMenuModel {
	folders := getTopLevelFolders(state)
	return &MainMenuModel{
		state:          SelectFolders,
		migrationState: state,
		folders:        folders,
		mainMenuOptions: []string{
			"Start Copying Selected Folders",
			"Generate Overall Report",
			"Quit",
		},
	}
}

// Init initializes the Main Menu UI.
func (m MainMenuModel) Init() tea.Cmd {
	return nil // No initial commands
}

// getTopLevelFolders extracts unique top-level folder names from the MigrationState.
// It also sets the initial status based on the migration state.
func getTopLevelFolders(state *MigrationState) []FolderItem {
	folderMap := make(map[string]FileStatus) // Use FileStatus to track overall folder status
	for _, file := range state.Files {
		parts := strings.SplitN(file.Path, string(os.PathSeparator), 2)
		if len(parts) > 0 && parts[0] != "" {
			folderName := parts[0]
			// If a file in this folder has failed, the folder status is Failed
			// If all files in a folder are Copied or Skipped, the folder status is Copied
			// Otherwise, it's Pending (or a mix)
			currentStatus, exists := folderMap[folderName]
			if !exists {
				folderMap[folderName] = file.Status
			} else {
				// Aggregate status: if any file failed, folder fails. If any pending, folder is pending.
				if file.Status == Failed {
					folderMap[folderName] = Failed
				} else if file.Status == Pending && currentStatus != Failed {
					folderMap[folderName] = Pending
				} else if file.Status == InProgress && currentStatus != Failed && currentStatus != Pending {
					folderMap[folderName] = InProgress
				}
			}
		}
	}

	var folderNames []string
	for name := range folderMap {
		folderNames = append(folderNames, name)
	}
	sort.Strings(folderNames)

	var items []FolderItem
	for _, name := range folderNames {
		status := folderMap[name]
		if status == "" { // Default to Pending if no specific file status set
			status = Pending
		}
		items = append(items, FolderItem{Name: name, Status: status})
	}
	return items
}

// Update handles messages and updates the MainMenuModel.
func (m MainMenuModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.Type {
		case tea.KeyCtrlC, tea.KeyEsc:
			m.done = true
			m.ChosenAction = "Quit"
			return m, tea.Quit

		case tea.KeyUp:
			if m.state == SelectFolders {
				if m.folderCursor > 0 {
					m.folderCursor--
				}
			} else if m.state == SelectAction {
				if m.actionCursor > 0 {
					m.actionCursor--
				}
			}

		case tea.KeyDown:
			if m.state == SelectFolders {
				if m.folderCursor < len(m.folders)-1 {
					m.folderCursor++
				}
			} else if m.state == SelectAction {
				if m.actionCursor < len(m.mainMenuOptions)-1 {
					m.actionCursor++
				}
			}

		case tea.KeySpace:
			if m.state == SelectFolders {
				if m.folderCursor >= 0 && m.folderCursor < len(m.folders) {
					m.folders[m.folderCursor].Selected = !m.folders[m.folderCursor].Selected
				}
			}

		case tea.KeyEnter:
			if m.state == SelectFolders {
				// Transition to selecting an action after folder selection
				m.state = SelectAction
			} else if m.state == SelectAction {
				m.ChosenAction = m.mainMenuOptions[m.actionCursor]
				return m, tea.Quit
			}
		}

	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
	}

	return m, nil
}

// View renders the Main Menu TUI.
func (m MainMenuModel) View() string {
	if m.done {
		return "Exiting...\n"
	}

	var s strings.Builder
	s.WriteString(fmt.Sprintf("Source: %s\nDestination: %s\n\n", m.migrationState.Source, m.migrationState.Destination))

	if m.state == SelectFolders {
		s.WriteString("Select folders to copy (Space to toggle, Enter to confirm selection):\n\n")
		for i, folder := range m.folders {
			cursorStr := "  "
			if m.folderCursor == i {
				cursorStr = menuCursor
			}
			checked := " "
			if folder.Selected {
				checked = "x"
			}
			status := ""
			if folder.Status == Copied {
				status = " [✓ Completed]"
			} else if folder.Status == Failed {
				status = " [✗ Failed]"
			} else if folder.Status == InProgress {
				status = " [~ In Progress]"
			}

			item := fmt.Sprintf("%s [%s] %s%s", cursorStr, checked, folder.Name, status)
			if m.folderCursor == i {
				s.WriteString(selectedItemStyle.Render(item))
			} else {
				s.WriteString(itemStyle.Render(item))
			}
			s.WriteString("\n")
		}
		s.WriteString("\n(Press Esc to quit, Enter to choose action)\n")

	} else if m.state == SelectAction {
		s.WriteString("What would you like to do with the selected folders?\n\n")
		for i, option := range m.mainMenuOptions {
			cursorStr := "  "
			if m.actionCursor == i {
				cursorStr = menuCursor
			}
			item := fmt.Sprintf("%s %s", cursorStr, option)
			if m.actionCursor == i {
				s.WriteString(selectedItemStyle.Render(item))
			} else {
				s.WriteString(itemStyle.Render(item))
			}
			s.WriteString("\n")
		}
		s.WriteString("\n(Press Esc to quit, Enter to confirm action)\n")
	}

	return dialogBoxStyle.Render(s.String())
}

// RunMainMenuUI starts the Main Menu TUI and returns the chosen action
// and the list of selected folder names.
func RunMainMenuUI(state *MigrationState) (chosenAction string, selectedFolders []string, err error) {
	p := tea.NewProgram(NewMainMenuModel(state))
	tm, err := p.Run()
	if err != nil {
		return "", nil, fmt.Errorf("error running main menu UI: %w", err)
	}

	m := tm.(*MainMenuModel)
	if m.done && m.ChosenAction == "" {
		return "Quit", nil, nil // User quit via Ctrl+C or Esc before making a selection
	}

	if m.ChosenAction == "Start Copying Selected Folders" {
		for _, folder := range m.folders {
			if folder.Selected {
				selectedFolders = append(selectedFolders, folder.Name)
			}
		}
	}
	return m.ChosenAction, selectedFolders, nil
}
