package main

import (
    "log"
    "os"
    "context"

    "github.com/urfave/cli/v3"
    "github.com/urfave/cli-altsrc/v3"
    yaml "github.com/urfave/cli-altsrc/v3/yaml"
)



func main() {
        Flags :[]cli.Flag{
            &cli.StringFlag{
                Name:        "file",
                Aliases:     []string{"f"},
                Value:       "/path/to/default",
                Usage:       "filename for mysql database",
                Destination: &filename,
            },
            &cli.StringFlag{
                Name:    "password",
                Aliases: []string{"p"},
                Usage:   "password for the mysql database",
                Sources: cli.NewValueSourceChain(yaml.YAML("somekey", altsrc.NewStringPtrSourcer(&filename))),
            },
        }
        if err := cmd.Run(context.Background(), os.Args); err != nil {
            log.Fatal(err)
        }
        
}
    
