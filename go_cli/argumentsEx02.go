package main

import (
    "fmt"
    "log"
    "os"
    "context"

    "github.com/urfave/cli/v3"
)

func main() {
    var ival int
    cmd := &cli.Command{
        Arguments: []cli.Argument{
            &cli.IntArg{
                Name: "someint",
                Destination: &ival,
            },
        },
        Action: func(ctx context.Context, cmd *cli.Command) error {
            fmt.Printf("We got %d", ival)
            return nil
        },
    }

    if err := cmd.Run(context.Background(), os.Args); err != nil {
        log.Fatal(err)
    }
}