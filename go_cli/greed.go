
//go:build greed

//go build -tags greed -o greed greed.go    打标签编译
package main

import (
	"fmt"
	"os"
	"log"
	"context"
	"github.com/urfave/cli/v3"
)

func main() {
	cmd :=&cli.Command{
		Name: "greet",
		Usage: "flight the loneliness!",
		Action: func(context.Context,*cli.Command) error {
			fmt.Println("hello friend")
			return nil
		},
	}

    if err := cmd.Run(context.Background(), os.Args); err != nil {
        log.Fatal(err)
    }
}