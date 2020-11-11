package main

import (
	"os"

	"github.com/mvisonneau/ocalver/internal/cli"
)

var version = ""

func main() {
	cli.Run(version, os.Args)
}
