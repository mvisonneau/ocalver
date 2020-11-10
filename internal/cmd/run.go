package cmd

import (
	"fmt"

	"github.com/mvisonneau/ocalver/pkg/ocalver"
	"github.com/urfave/cli/v2"
)

// Run generates a calver based on the provided configuration
func Run(ctx *cli.Context) (int, error) {
	ver, err := ocalver.Generate(configure(ctx))
	if err != nil {
		return 1, err
	}

	fmt.Println(ver)
	return 0, nil
}
