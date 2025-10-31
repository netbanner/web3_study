package main

import (
    "context"
    "encoding/json"
    "fmt"
    "log"
    "os"

    "github.com/urfave/cli/v3"
)

func main(){
	cmd :=&cli.Command{
		Name: "authors",
		MutuallyExclusiveFlags: []cli.MutuallyExclusiveFlags{
            {
                Required: true,
                Flags: [][]cli.Flag{
                    {
                        &cli.StringFlag{
                            Name:  "login",
                            Usage: "the username of the user",
                        },
                    },
                    {
                        &cli.StringFlag{
                            Name:  "id",
                            Usage: "the user id (defaults to 'me' for current user)",
                        },
                    },
                },
            },
		},
		Action: func (ctx context.Context,cmd *cli.Command) error {
			u, err := getUser(ctx, cmd)
            if err != nil {
                return err
            }
            data, err := json.Marshal(u)
            if err != nil {
                return err
            }
            fmt.Println(string(data))
            return nil
			
		},
	}

    if err := cmd.Run(context.Background(), os.Args); err != nil {
        log.Fatal(err)
    }
}

type User struct {
	Id string `json:"id"`
	Login string `json:"login"`
	FirstName string `json:"firstName"`
	LastName string `json:"lastName"`
}

func getUser(ctx context.Context,cmd *cli.Command)(User,error)  {
	u := User{
        Id:        "abc123",
        Login:     "vwoolf@example.com",
        FirstName: "Virginia",
        LastName:  "Woolf",
    }
    if login := cmd.String("login"); login != "" {
        fmt.Printf("Getting user by login: %s\n", login)
        u.Login = login
    }
    if id := cmd.String("id"); id != "" {
        fmt.Printf("Getting user by id: %s\n", id)
        u.Id = id
    }
    return u, nil
	
}