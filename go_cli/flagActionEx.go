package main

import (
    "log"
    "os"
    "fmt"
    "context"

    "github.com/urfave/cli/v3"
)

func main() {
    cmd := &cli.Command{
        Flags: []cli.Flag{
            &cli.IntFlag{
                Name:        "port",
                Usage:       "Use a randomized port",
                Value:       0,
                DefaultText: "random",
                Action: func(ctx context.Context, cmd *cli.Command, v int) error {
                    if v >= 65536 {
                        return fmt.Errorf("Flag port value %v out of range[0-65535]", v)
                    }
                    return nil
                },
            },
        },
    }

    if err := cmd.Run(context.Background(), os.Args); err != nil {
        log.Fatal(err)
    }
}