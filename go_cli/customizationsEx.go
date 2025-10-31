package main

import (
    "fmt"
    "log"
    "os"
    "context"

    "github.com/urfave/cli/v3"
)
func main()  {
	tasks :=[]string{"cook","clean","laundry","eat","sleep","code"}
	cmd := &cli.Command{
        EnableShellCompletion: true,
        Commands: []*cli.Command{
            {
                Name:    "complete",
                Aliases: []string{"c"},
                Usage:   "complete a task on the list",
                Action: func(ctx context.Context, cmd *cli.Command) error {
                    fmt.Println("completed task: ", cmd.Args().First())
                    return nil
                },
                ShellComplete: func(ctx context.Context, cmd *cli.Command) {
                    // This will complete if no args are passed
                    if cmd.NArg() > 0 {
                        return
                    }
                    for _, t := range tasks {
                        fmt.Println(t)
                    }
                },
            },
        },
	}
	
	if err := cmd.Run(context.Background(), os.Args); err != nil {
        log.Fatal(err)
    }
}