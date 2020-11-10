package cli

import (
	"fmt"
	"os"
	"time"

	"github.com/urfave/cli/v2"

	"github.com/mvisonneau/ocalver/internal/cmd"
)

// Run handles the instanciation of the CLI application
func Run(version string, args []string) {
	err := NewApp(version, time.Now()).Run(args)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

// NewApp configures the CLI application
func NewApp(version string, start time.Time) (app *cli.App) {
	app = cli.NewApp()
	app.Name = "ocalver"
	app.Version = version
	app.Usage = "Opinionated CalVer generator"
	app.EnableBashCompletion = true

	app.Flags = cli.FlagsByName{
		&cli.StringFlag{
			Name:    "pre",
			Aliases: []string{"p"},
			Usage:   "generates a prerelease using the provided value as a `key`",
		},
		&cli.StringFlag{
			Name:    "repository",
			Aliases: []string{"r"},
			Usage:   "`path` where your git repository is available",
			Value:   ".",
		},
	}

	app.Action = cmd.ExecWrapper(cmd.Run)

	app.Metadata = map[string]interface{}{
		"startTime": start,
	}

	return
}
