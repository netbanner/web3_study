package main
import (
	"fmt"
	"log"
	"os"
	"context"
	"github.com/urfave/cli/v3"
)

func main(){
	var count int 
	cmd :=&cli.Command{
		UseShortOptionHandling: true,
		Flags: []cli.Flag{
			&cli.BoolFlag{
				Name: "foo",
				Usage: "foo greeting",
				Aliases: []string{"f"},
				Config: cli.BoolConfig{
					Count: &count,
				},
			},
		},
		Action: func(ctx context.Context, cmd *cli.Command) error {
            fmt.Println("count", count)
            return nil
		},
	}
	if err := cmd.Run(context.Background(), os.Args); err != nil {
        log.Fatal(err)
    }
}