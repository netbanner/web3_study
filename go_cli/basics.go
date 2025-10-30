package main

import (
    "fmt"
    "log"
    "os"
    "context"

    "github.com/urfave/cli/v3"
)

func main() {
	cmd :=&cli.Command{
		Flags: []cli.Flag{
		&cli.StringFlag{
			Name: "lang",
			Value: "english",
			Usage: "language for the greeting",
			},
		},
		Action: func(ctx context.Context,cmd *cli.Command) error  {
			name :="Nefertiti"
			if cmd.NArg()>0{
				name = cmd.Args().Get(0)
				fmt.Println("参数：",cmd.Args())
			}
			if cmd.String("lang")=="spanish" {
				fmt.Println("Hola",name)
			}else {
				fmt.Println("Hello",name)
			}
			return nil
		},
	}
	if err := cmd.Run(context.Background(), os.Args); err != nil {
        log.Fatal(err)
    }
}