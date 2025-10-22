package main

import "fmt"

func main()  {

	a, b := 1,2
	sum := a+b
	sub := a-b
	mul := a*b	
	div := a/b
	mod :=a%b

	fmt.Println(sum,sub,mul,div,mod)
	a++
	b--

	c := 10+0.1
	d :=byte(1)+1
	fmt.Println(c,d)

	sum1 := c + float64(d)
    fmt.Println(sum1)

    sub1 := byte(c) - d
    fmt.Println(sub1)

    mul1 := c * float64(d)
    div1 := byte(c) / d

	fmt.Println(mul1,div1)
	
	fmt.Println(a == b)
	fmt.Println(a != b)
	fmt.Println(a > b)
	fmt.Println(a < b)
	fmt.Println(a >= b)
	fmt.Println(a <= b)

	e := true
	f := false

	
	fmt.Printf("-----------------")
	fmt.Println(e && f)
	fmt.Println(e || f)
	fmt.Println(!(e && f))	

	fmt.Println(0 & 0)
	fmt.Println(0 | 0)
	fmt.Println(0 ^ 0)

	fmt.Println(0 & 1)
	fmt.Println(0 | 1)
	fmt.Println(0 ^ 1)

	fmt.Println(1 & 1)
	fmt.Println(1 | 1)
	fmt.Println(1 ^ 1)

	fmt.Println(1 & 0)
	fmt.Println(1 | 0)
	fmt.Println(1 ^ 0)

	fmt.Printf("----------------- \n")

	g,h := 1,2
	var i  int 
	i = g+h
	fmt.Println("i = g + h, i =", i)

	plusAssignment(i, a)
    subAssignment(i, a)
    mulAssignment(i, a)
    divAssignment(i, a)
    modAssignment(i, a)
    leftMoveAssignment(i, a)
    rightMoveAssignment(i, a)
    andAssignment(i, a)
    orAssignment(i, a)
	norAssignment(i, a)
	
	
}

func plusAssignment(c,a int){
	c +=a // c= c+a
	fmt.Println("c += a, c =", c)
}

func subAssignment(c, a int) {
    c -= a // c = c - a
    fmt.Println("c -= a, c =", c)
}

func mulAssignment(c, a int) {
    c *= a // c = c * a
    fmt.Println("c *= a, c =", c)
}

func divAssignment(c, a int) {
    c /= a // c = c / a
    fmt.Println("c /= a, c =", c)
}

func modAssignment(c, a int) {
    c %= a // c = c % a
    fmt.Println("c %= a, c =", c)
}

func leftMoveAssignment(c, a int) {
    c <<= a // c = c << a
    fmt.Println("c <<= a, c =", c)
}

func rightMoveAssignment(c, a int) {
    c >>= a // c = c >> a
    fmt.Println("c >>= a, c =", c)
}

func andAssignment(c, a int) {
    c &= a // c = c & a
    fmt.Println("c &= a, c =", c)
}

func orAssignment(c, a int) {
    c |= a // c = c | a
    fmt.Println("c |= a, c =", c)
}

func norAssignment(c, a int) {
    c ^= a // c = c ^ a
    fmt.Println("c ^= a, c =", c)
}