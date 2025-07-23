package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"

	"github.com/fatih/color"
	"github.com/urfave/cli/v2"
)

const (
	version = "2.0.0"
	description = "PAK.sh - Universal Package Automation Kit Wrapper"
)

func main() {
	app := &cli.App{
		Name:        "pak-sh",
		Version:     version,
		Description: description,
		Usage:       "Professional wrapper for PAK.sh installation and management",
		Commands: []*cli.Command{
			{
				Name:    "install",
				Aliases: []string{"i"},
				Usage:   "Install PAK.sh locally",
				Action:  installPak,
			},
			{
				Name:    "run",
				Aliases: []string{"r"},
				Usage:   "Run PAK.sh command",
				Action:  runPak,
			},
			{
				Name:    "status",
				Aliases: []string{"s"},
				Usage:   "Check PAK.sh installation status",
				Action:  checkStatus,
			},
			{
				Name:    "update",
				Aliases: []string{"u"},
				Usage:   "Update PAK.sh installation",
				Action:  updatePak,
			},
			{
				Name:    "version",
				Aliases: []string{"v"},
				Usage:   "Show version information",
				Action:  showVersion,
			},
		},
		UsageText: "pak-sh <command> [options]",
		Authors: []*cli.Author{
			{
				Name:  "PAK.sh Team",
				Email: "team@pak.sh",
			},
		},
		Copyright: "Copyright 2024 PAK.sh Team",
		Action: func(c *cli.Context) error {
			fmt.Println("PAK.sh Wrapper - Universal Package Automation Kit")
			fmt.Println("==================================================")
			fmt.Println()
			fmt.Println("Usage:")
			fmt.Println("  pak-sh install     Install PAK.sh locally")
			fmt.Println("  pak-sh run <cmd>   Run PAK.sh command")
			fmt.Println("  pak-sh status      Check installation status")
			fmt.Println("  pak-sh update      Update PAK.sh installation")
			fmt.Println("  pak-sh version     Show version information")
			fmt.Println()
			fmt.Println("Examples:")
			fmt.Println("  pak-sh install")
			fmt.Println("  pak-sh run deploy my-package")
			fmt.Println("  pak-sh run web start")
			fmt.Println()
			fmt.Println("For more information, visit: https://pak.sh")
			return nil
		},
	}

	err := app.Run(os.Args)
	if err != nil {
		color.Red("Error: %v", err)
		os.Exit(1)
	}
}

func installPak(c *cli.Context) error {
	color.Blue("🚀 Installing PAK.sh...")
	
	// Find wrapper script
	wrapperPath, err := findWrapperScript()
	if err != nil {
		return fmt.Errorf("wrapper script not found: %v", err)
	}

	// Execute wrapper install command
	cmd := exec.Command(wrapperPath, "install")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	
	return cmd.Run()
}

func runPak(c *cli.Context) error {
	if c.NArg() == 0 {
		return fmt.Errorf("no command specified")
	}

	// Find wrapper script
	wrapperPath, err := findWrapperScript()
	if err != nil {
		return fmt.Errorf("wrapper script not found: %v", err)
	}

	// Build command with arguments
	args := append([]string{"run"}, c.Args().Slice()...)
	cmd := exec.Command(wrapperPath, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin
	
	return cmd.Run()
}

func checkStatus(c *cli.Context) error {
	color.Blue("🔍 Checking PAK.sh installation status...")
	
	// Find wrapper script
	wrapperPath, err := findWrapperScript()
	if err != nil {
		return fmt.Errorf("wrapper script not found: %v", err)
	}

	// Execute wrapper status command
	cmd := exec.Command(wrapperPath, "status")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	
	return cmd.Run()
}

func updatePak(c *cli.Context) error {
	color.Blue("🔄 Updating PAK.sh...")
	
	// Find wrapper script
	wrapperPath, err := findWrapperScript()
	if err != nil {
		return fmt.Errorf("wrapper script not found: %v", err)
	}

	// Execute wrapper update command
	cmd := exec.Command(wrapperPath, "update")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	
	return cmd.Run()
}

func showVersion(c *cli.Context) error {
	fmt.Printf("PAK.sh Wrapper v%s\n", version)
	fmt.Printf("Go version: %s\n", runtime.Version())
	fmt.Printf("Platform: %s/%s\n", runtime.GOOS, runtime.GOARCH)
	return nil
}

func findWrapperScript() (string, error) {
	// Get the directory of the current executable
	exe, err := os.Executable()
	if err != nil {
		return "", err
	}
	
	exeDir := filepath.Dir(exe)
	
	// Look for pak-sh script in the same directory
	wrapperPath := filepath.Join(exeDir, "pak-sh")
	if runtime.GOOS == "windows" {
		wrapperPath += ".exe"
	}
	
	if _, err := os.Stat(wrapperPath); err == nil {
		return wrapperPath, nil
	}
	
	// Look for pak-sh script in current directory
	currentDir, err := os.Getwd()
	if err != nil {
		return "", err
	}
	
	wrapperPath = filepath.Join(currentDir, "pak-sh")
	if runtime.GOOS == "windows" {
		wrapperPath += ".exe"
	}
	
	if _, err := os.Stat(wrapperPath); err == nil {
		return wrapperPath, nil
	}
	
	return "", fmt.Errorf("pak-sh wrapper script not found")
} 