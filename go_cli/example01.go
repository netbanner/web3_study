//go:build ex1
package main

import (
	"os"
	"context"
	"github.com/urfave/cli/v3"
)


func main() {
	(&cli.Command{}).Run(context.Background(),os.Args)
}