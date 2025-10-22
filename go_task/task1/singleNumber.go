package main

import "fmt"

func main(){

	 a :=[]int{1,1,2,2,3,3,4}
	 fmt.Println("只出现一次的数字是:", singleNumber(a))
}

func singleNumber(nums []int) int {
	m :=make(map[int]int)
	for _,v := range nums{
		m[v]++
	}

	for k,_ :=range m{
		if(m[k]==1){
			return k
		}
	}
	
	return -1;
}