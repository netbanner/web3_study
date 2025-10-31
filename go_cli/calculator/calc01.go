package main


import (
	"context"
	"errors"
	"fmt"
	"log"
	"os"
	"strconv"

	"github.com/urfave/cli/v3"
)

func main()  {
	app:=&cli.Command{
		Name: "calc",
		Usage: "simple Cli calculor",
		Commands: []*cli.Command{
			{
				Name: "add",
				Aliases: []string{"+"},
				Usage: "add two inteters",
				Action: func(ctx context.Context,cmd *cli.Command) error  {
					a,b,err := parseTwoArgs(cmd.Args())
					if err!=nil{
						return err
					}
					fmt.Println("a+b=:",a+b)
					return nil
				},
			},
			{
				Name: "sub",
				Aliases: []string{"-"},
				Usage: "substract two inteters",
				Action: func(ctx context.Context,cmd *cli.Command) error  {
					a,b,err := parseTwoArgs(cmd.Args())
					if err!=nil{
						return err
					}
					fmt.Println("a-b=:",a-b)
					return nil
				},
			},
			{
				Name: "mul",
				Aliases: []string{"*"},
				Usage: "multiply two inteters",
				Action: func(ctx context.Context,cmd *cli.Command) error  {
					a,b,err := parseTwoArgs(cmd.Args())
					if err!=nil{
						return err
					}
					fmt.Println("a*b=:",a*b)
					return nil
				},
			},
			{
				Name:  "div",
				Usage: "divide two integers",
				Aliases: []string{"/"},
				Action: func(ctx context.Context, cmd *cli.Command) error {
					a, b, err := parseTwoArgs(cmd.Args())
					if err != nil {
						return err
					}
					if b == 0 {
						return errors.New("division by zero")
					}
					fmt.Println("a/b=:",a / b)
					return nil
				},
			},
			{
				Name:  "mod",
				Usage: "modulo two integers",
				Aliases: []string{"%"},
				Action: func(ctx context.Context, cmd *cli.Command) error {
					a, b, err := parseTwoArgs(cmd.Args())
					if err != nil {
						return err
					}
					if b == 0 {
						return errors.New("modulo by zero")
					}
					fmt.Println(a % b)
					return nil
				},
			},
			{
				Name:  "quit",
				Usage: "quit calculator",
				Aliases: []string{"q"},
				Action: func(context.Context, *cli.Command) error {
					fmt.Println("quit calculator!")
					os.Exit(0)
					return nil
				},
				Hidden: false, // 可见
			},
		},
	}
	if err := app.Run(context.Background(), os.Args); err != nil {
		log.Fatal(err)
	}
}

func parseTwoArgs(args cli.Args) (int64, int64, error) {
	if args.Len()!=2{
		return 0,0,errors.New("需要两个参数")
	}
	a, err1 := strconv.ParseInt(args.Get(0), 10, 64)
	b, err2 := strconv.ParseInt(args.Get(1), 10, 64)
	if err1 != nil || err2 != nil {
		return 0, 0, errors.New("参数必须是整数")
	}
	return a, b, nil
}