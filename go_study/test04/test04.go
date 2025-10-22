package main

import "fmt"	

func main() {

	var p1 *int
	var p2 *string
	 i :=1
	 s :="sss"

	 p1 = &i
	 p2 = &s

	 p3 := &p2

	fmt.Println(p1)
	fmt.Println(p2)
	fmt.Println(p3)
	fmt.Println(*p1 == i)

	*p1 = 2
	fmt.Println(i)	

	fmt.Println("----------------")
	
	 a := 2
	 var p4 *int
	 fmt.Println("a=",&a)
	  p4 = &a
	 fmt.Println("p4=",p4)

	 var pp **int
	pp = &p4
	fmt.Println(pp, p4)
	**pp = 3
	fmt.Println(pp, *pp, p4)
	fmt.Println(**pp, *p4)
	fmt.Println(a, &a)
	
	//a5 := "Hello, world!"
	//upA := uintptr(unsafe.Pointer(&a5))
	//upA += 1

	//c := (*uint8)(unsafe.Pointer(upA))
	//fmt.Println(*c)
}