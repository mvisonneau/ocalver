package main

import (
	"os"

	_ "github.com/go-git/go-billy/v5"
	"github.com/mvisonneau/ocalver/internal/cli"
)

var version = ""

func main() {
	cli.Run(version, os.Args)
}
