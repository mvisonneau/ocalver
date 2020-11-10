package cmd

import (
	"github.com/mvisonneau/ocalver/pkg/ocalver"

	log "github.com/sirupsen/logrus"
	"github.com/urfave/cli/v2"
)

func configure(ctx *cli.Context) ocalver.Config {
	return ocalver.Config{
		Pre:            ctx.String("pre"),
		RepositoryPath: ctx.String("repository"),
	}
}

func exit(exitCode int, err error) cli.ExitCoder {
	if err != nil {
		log.Error(err.Error())
	}
	return cli.NewExitError("", exitCode)
}

// ExecWrapper gracefully logs and exits our `run` functions
func ExecWrapper(f func(ctx *cli.Context) (int, error)) cli.ActionFunc {
	return func(ctx *cli.Context) error {
		return exit(f(ctx))
	}
}
