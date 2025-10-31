package main

import (
    "fmt"
    "log"
    "os"
    "context"

    "github.com/urfave/cli/v3"
)

func main() {
	var ivals []int
    cmd := &cli.Command{
        Arguments: []cli.Argument{
            &cli.IntArgs{
				// 表示从0 ，-1到索引末尾
                Name: "someint",
                Min: 0,
				Max: -1,
				Destination: &ivals,
            },
        },
        Action: func(ctx context.Context, cmd *cli.Command) error {
			fmt.Println("We got ", cmd.IntArgs("someint"))
			fmt.Println("He got ", ivals)
            return nil
        },
    }

    if err := cmd.Run(context.Background(), os.Args); err != nil {
        log.Fatal(err)
    }
}