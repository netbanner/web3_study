package main

import "fmt"

func main()  {
	
	var s1 []int = []int{}

	var s2 = []int{}

	s3 := []int{}

	s4 := []int{1,2,3,4}

	s5 :=make([]int, 0)

	s6 :=make([]int,2,4)

	a :=[5]int{6,5,4,3,2}
	fmt.Println(s1)
	fmt.Println(s2)
	fmt.Println(s3)
	fmt.Println(s4)
	fmt.Println(s5)
	fmt.Println(s6)
	fmt.Println(a)

	arr :=[6]int{1,2,3,4,5,6}
	s7 :=arr[2:]
	s8 :=arr[1:3]
	s9 :=arr[:2]
	fmt.Println(s7)
	fmt.Println(s8)
	fmt.Println(s9)
	arr[0] =9
	arr[1] = 8
	arr[2] = 7
	fmt.Println(s7)
	fmt.Println(s8)
	fmt.Println(s9)

	fmt.Println(s9[0])
	fmt.Println("s9 len=",len(s9),"s9 cap =",cap(s9))
	s9 = append(s9)
	fmt.Println(s9)
	s9 = append(s9,2,3,4,5,6,7)
	fmt.Println(s9)
  //[9 8 2 3 4 5 6 7]
	//指定位置添加元素 如第二个所有添加 10
	s9 = append(s9[:2],append([]int{10},s9[2:]...)...)
	fmt.Println(s9)


	src1 :=[]int{1,2,3}
	dst1 :=make([]int,4,5)

	src2 :=[]int{1,2,3,4,5}
	dst2 :=make([]int,3,3)
	fmt.Println("before copy, src1 = ", src1)
	fmt.Println("before copy, dst1 = ", dst1)

	fmt.Println("before copy, src2 = ", src2)
	fmt.Println("before copy, dst2 = ", dst2)

	copy(dst1,src1)
	copy(dst2,src2)

	fmt.Println("after copy, src1 = ", src1)
	fmt.Println("after copy, dst1 = ", dst1)

	fmt.Println("after copy, src2 = ", src2)
	fmt.Println("after copy, dst2 = ", dst2)





}