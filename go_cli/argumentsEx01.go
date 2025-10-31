package main

import (
	"fmt"
	"log"
	"os"
	"context"
	"github.com/urfave/cli/v3"
)

func main(){
	cmd := &cli.Command{
		Action: func(ctx context.Context,cmd *cli.Command) error  {
			fmt.Printf("Number of args: %d\n",cmd.Args().Len())
			var out string 
			for i:=0;i<cmd.Args().Len();i++{
				out = out + fmt.Sprintf(" %v",cmd.Args().Get(i))
			}
			fmt.Printf("hello %v",out)
			return nil
		},
	}

	if err := cmd.Run(context.Background(), os.Args); err != nil {
        log.Fatal(err)
    }
}