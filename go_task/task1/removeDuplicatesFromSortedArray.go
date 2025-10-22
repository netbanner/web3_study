package main


import "fmt"

func main(){

	nums :=[]int{0,0,1,1,1,2,2,3,3,4}
	fmt.Println("重复元素",removeDuplicate(nums))

}


func removeDuplicate( nums []int) int {
	j :=1
	 
	for i:=1;i<len(nums);i++{
		if nums[i]!=nums[i-1] {
			nums[j] = nums[i]
			j++
		}
	}
	fmt.Println("数组：",nums)
	return j

}