package main

import (
    "log"
    "os"
    "context"

    "github.com/urfave/cli/v3"
)


func main() {
	cmd := &cli.Command{
		Flags :[]cli.Flag{
			&cli.StringFlag{
				Name:    "lang",
                Aliases: []string{"l"},
                Value:   "english",
                Usage:   "language for the greeting",
				//Sources: cli.EnvVars("LEGACY_COMPAT_LANG", "APP_LANG", "LANG"),
				
				Sources: cli.Files("./go.sum"),
			},
		},
	}
	if err := cmd.Run(context.Background(), os.Args); err != nil {
        log.Fatal(err)
    }
}