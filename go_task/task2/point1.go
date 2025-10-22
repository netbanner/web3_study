package main

import "fmt"


func main(){

	num :=10
	fmt.Println("调用前:",num)

	fmt.Println("值传递：",add(num))
	fmt.Println("值传递调用后:",num)
	addPoint(&num)
	fmt.Println("指针调用后:",num)

}

// 值传递
func add( num int) int{

	return num+10
}

//指针的引用 引用转递

func addPoint(num *int)  {
	 *num +=10
}