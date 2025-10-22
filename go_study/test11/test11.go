package main

import (
	"fmt"
	"time"
)
 var g  int
func main() {
	
	var a int 
	if b:=1;b==0{
		fmt.Println("b==0")
	}else{
		 c := 2
		 fmt.Println(" declare c = ",c)
		 fmt.Println("b==1")
	}

	switch d:=3;d {
	case 1:
		 e:=4
		 fmt.Println("declare e = ",e)
		 fmt.Println("d==1")
	case 3:
		 f :=4
		 fmt.Println("declare f = ",f)
		 fmt.Println("d==3")
	}

	for i :=0;i<1;i++{
		 forA :=1
		 fmt.Println("forA ==",forA)
	}

	select {
	case <-time.After(time.Second):
		selectA :=1
		fmt.Println("selectA = ",selectA)
	}
	//匿名代码快
	{
		blockA :=1
		fmt.Println("blockA = ",blockA)
	}

	fmt.Println("a = ",a)

	fmt.Println("-------- 全局变量-----")
	{
	fmt.Println("global variable, g = ", g)
        g = 3
        fmt.Println("global variable, g = ", g)

        g := 10
        fmt.Println("local variable, g = ", g)
        g--
        fmt.Println("local variable, g = ", g)
	}
	fmt.Println("global variable, g = ", g)

	var h int = 4
    fmt.Println("local variable, h = ", h)
    if h := 3; h == 3 {
        fmt.Println("if statement, h = ", h)
        h--
        fmt.Println("if statement, h = ", h)
    }
    fmt.Println("local variable, h = ", h)

}

