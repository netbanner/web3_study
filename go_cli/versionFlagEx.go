package main

import (
    "fmt"
    "os"
    "context"

    "github.com/urfave/cli/v3"
)

var (
    Revision = "fafafaf"
)

func main() {
	cli.VersionFlag = &cli.BoolFlag{
        Name:    "print-version",
        Aliases: []string{"V"},
        Usage:   "print only the version",
    }

    cli.VersionPrinter = func(cmd *cli.Command) {
        fmt.Printf("version=%s revision=%s\n", cmd.Root().Version, Revision)
    }

    cmd := &cli.Command{
        Name:    "partay",
        Version: "v19.99.0",
    }
    cmd.Run(context.Background(), os.Args)
}