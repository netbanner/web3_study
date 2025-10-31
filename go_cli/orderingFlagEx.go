package main

import (
    "log"
    "os"
    "sort"
    "context"

    "github.com/urfave/cli/v3"
)

func main(){
	cmd :=&cli.Command{
		Flags: []cli.Flag{
			&cli.StringFlag{
                Name:    "lang",
                Aliases: []string{"l"},
                Value:   "english",
                Usage:   "Language for the greeting",
            },
            &cli.StringFlag{
                Name:    "config",
                Aliases: []string{"c"},
                Usage:   "Load configuration from `FILE`",
            },
		},
		Commands: []*cli.Command{
			{
				Name: "commplete",
				Aliases: []string{"c"},
				Usage:   "complete a task on the list",
                Action: func(ctx context.Context, cmd *cli.Command) error {
                    return nil
                },
			},
			{
				Name:    "add",
                Aliases: []string{"a"},
                Usage:   "add a task to the list",
                Action: func(ctx context.Context, cmd *cli.Command) error {
                    return nil
                },
			},
		},
	}

	sort.Sort(cli.FlagsByName(cmd.Flags))
	if err := cmd.Run(context.Background(), os.Args); err != nil {
        log.Fatal(err)
    }
}