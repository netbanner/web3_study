package main

import "fmt"


func main(){

	//仅声明
	var a [5]int 
	fmt.Println("a = ",a)

	var marr [2]map[string]string
	fmt.Println("marr =",marr)
 // map的零值是nil，虽然打印出来是非空值，但真实的值是nil
    // marr[0]["test"] = "1"

	//声明以及初始化
	var b [7]int = [7] int{1,2,3,4,5,6,7}
	fmt.Println("b = ",b)

	//类型推导声明方式
	var c =[5]string{"c1","c2","c3","c4","c5"}
	fmt.Println("c = ",c)

	 d := [3]int{1,2,3}
	 fmt.Println("d=",d)
	 
	 //使用 ... 代替数组长度
	 e := [...]string{"e1","e2","e3","e4"}
	 fmt.Println("e = ",e)

	 //声明时初始化指定下标的元素值
	   // 声明时初始化指定下标的元素值
	   positionInit := [5]string{1: "position1", 3: "position3"}
	   fmt.Println("positionInit = ", positionInit)
	   
	 element :=b[2]
	 fmt.Println("element = ",element)

	 for i,v := range b{
		 fmt.Println("index = ",i,"value = ",v)
	 }
	 for i := range b{
		fmt.Println("only index, index = ", i)
	 }

	 fmt.Println("len(b) = ",len(b))

	 // 使用下标，for循环遍历数组
	 for i := 0; i < len(b); i++ {
        fmt.Println("use len(), index = ", i, "value = ", b[i])
	}
	
	 f := [3][2]int{
		 {0,1},
		 {2,3},
		 {4,5},
	 }

	 fmt.Println("f = ",f)

	 g := [3][2][2] int{
		 {{0,1},{2,3}},
		 {{3,4},{4,5}},
		 {{5,6},{7,8}},
		 }
	 
	 fmt.Println(" g= ",g)

	  h := [3][3][3]int{}
		   h[2][2][1] = 5
		   h[1][2][1] = 2
	  
	  fmt.Println("h = ",h)

	  layer1 :=g[0]
	  layer2 :=g[0][1]
	  element2 :=g[0][1][1]
	  fmt.Println(layer1)
	  fmt.Println(layer2)
	  fmt.Println(element2)

	  for i,v :=range g {
		  fmt.Println("index = ",i,"value = ",v)
		  for j,inner :=range v {
			fmt.Println("inner ,index = ",j,"value = ",inner)
		  }
	  }
}