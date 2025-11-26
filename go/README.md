# Large User Files Manager (Go)

Go implementation of the large user files management tool.

## Building

### Windows
```bash
cd go
go build -o userfiles-manager.exe .
```

### Cross-compile for Linux
```bash
GOOS=linux GOARCH=amd64 go build -o userfiles-manager-linux .
```

### Cross-compile for macOS
```bash
GOOS=darwin GOARCH=amd64 go build -o userfiles-manager-mac .
```

## Running

After building:
```bash
.\userfiles-manager.exe
```

## Features

- Interactive TUI menu
- Scan for large files (configurable size threshold)
- Generate formatted reports
- Migrate files to D: drive with SHA256 verification
- Safe copy-then-delete approach
- Comprehensive exclusion list (protects AppData, cloud sync, dev tools)
- Color-coded output
- Detailed logging

## Dependencies

- `github.com/fatih/color` - Terminal colors
- `github.com/manifoldco/promptui` - Interactive prompts

Install dependencies:
```bash
go mod download
```

## Building Standalone Binary

The compiled binary is completely standalone with no dependencies:
```bash
go build -ldflags="-s -w" -o userfiles-manager.exe .
```

Flags:
- `-s` - Strip debug symbols
- `-w` - Strip DWARF debugging info
- Results in smaller binary size
