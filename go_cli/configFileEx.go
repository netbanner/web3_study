package main
import (
	"log"
	"os"
	"context"
	"github.com/urfave/cli/v3"
)


func main(){
	cmd := &cli.Command{
        Flags: []cli.Flag{
            &cli.StringFlag{
                Name:    "config",
                Aliases: []string{"c"},
                Usage:   "Load configuration from `FILE`",
            },
        },
	}
	if err := cmd.Run(context.Background(), os.Args); err != nil {
        log.Fatal(err)
    }

}