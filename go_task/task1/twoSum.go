package main

import "fmt"


func twoSum(nums []int, target int) []int {

	 m :=make(map[int]int)

	 for i:=0;i<len(nums);i++{
		  v :=nums[i]
		 _,exist := m[target-v]
		 if exist{
			 return []int{m[target-v],i}
		 }
		 m[v] = i
	 }
    return nil
}


func main(){

	 nums :=[]int{2,7,11,15}
	 target :=9

	 fmt.Println("两数之和:",twoSum(nums,target))

}