package main


import (
	"fmt"
	_ "github.com/netbanner/learn/init_order/pk1"
)

const mainName string = "main"

var mainVar string = getMainVar()

func init() {
    fmt.Println("main init method invoked")
}

func main() {
    fmt.Println("main method invoked!")
}

func getMainVar() string {
    fmt.Println("main.getMainVar method invoked!")
    return mainName
}