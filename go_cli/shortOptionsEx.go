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
		UseShortOptionHandling: true,
		Commands: []*cli.Command{
			{
				Name: "short",
				Usage : "complete a task on the list",
				Flags : []cli.Flag{
					&cli.BoolFlag{Name: "serve", Aliases: []string{"s"}},
                    &cli.BoolFlag{Name: "option", Aliases: []string{"o"}},
                    &cli.StringFlag{Name: "message", Aliases: []string{"m"}},
				},
				Action: func(ctx context.Context,cmd *cli.Command) error{
					fmt.Println("serve:",cmd.Bool("serve"))
					fmt.Println("option:",cmd.Bool("option"))
					fmt.Println("message:",cmd.String("message"))

					return nil
				},
			},
		},
	}
	if err := cmd.Run(context.Background(), os.Args); err != nil {
        log.Fatal(err)
    }
}