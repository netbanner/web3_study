package main

import "fmt"



func main() {

	var s1 string = "Hello"
	var zero int
	var b1 = true

	var (
		i int = 123
		b2 bool
		s2 = "test"
	)

	var (
		group = 2
	)

	 fmt.Println("s1=",s1)
	 fmt.Println("zero=",zero)
	 fmt.Println("b1=",b1)
	 fmt.Println("i=",i)
	 fmt.Println("b2=",b2)
	 fmt.Println("s2=",s2)
	 fmt.Println("group=",group)

	 method()

}

var a, b, c int = 1, 2, 3

var e, f, g int

var h, i, j = 1, 2, "test"

 func method(){
	var k, l, m int = 1, 2, 3
    var n, o, p int
    q, r, s := 1, 2, "test"
    fmt.Println(k, l, m, n, o, p, q, r, s)
 }