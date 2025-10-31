package main 

import (
	"log"
	"os"
	"context"
	"github.com/urfave/cli/v3"
)
func main(){
	cmd :=&cli.Command{
		Commands: []*cli.Command{
			{
				Name: "noop",
			},
			{
				Name: "add",
				Category: "template",
			},
			{
				Name: "remove",
				Category: "template",
			},
		},
	}
	if err := cmd.Run(context.Background(), os.Args); err != nil {
        log.Fatal(err)
    }
}