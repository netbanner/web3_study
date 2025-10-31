package main

import (
    "log"
    "os"
    "context"

    "github.com/urfave/cli/v3"
)

func main() {
    cmd := &cli.Command{
        Flags: []cli.Flag{
            &cli.BoolFlag{
                Name:  "ginger-crouton",
                Usage: "is it in the soup?",
            },
        },
        Action: func(ctx context.Context, cmd *cli.Command) error {
            if !cmd.Bool("ginger-crouton") {
                return cli.Exit("Ginger croutons are not in the soup", 86)
            }
            return nil
        },
    }

    if err := cmd.Run(context.Background(), os.Args); err != nil {
        log.Fatal(err)
    }
}