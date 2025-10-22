package main


import ("fmt"
"sync")





package main

import "fmt"

// 值传递：改元素有效，改 len/cap 无效
func mulTwo(nums []int) []int {
	for i := range nums {
		nums[i] *= 10
	}
	return nums
}

// 指针传递：既能改元素，也能改 len/cap
func doubleSlice(p *[]int) {
	s := *p
	for i := range s {
		s[i] *= 10
	}
}

func main() {
	nums := []int{1, 2, 3, 5, 6, 10}
	fmt.Println("调用前：", nums)

	mulTwo(nums) // 值传递，但底层数组被改
	fmt.Println("值传递后：", nums)
	var wg sync.WaitGroup
	
	
	doubleSlice(&nums) // 指针传递
	fmt.Println("指针后：", nums)
}
/*
你这段代码其实两种写法都成功地把元素乘了 10，但「值传递」看起来也改了，于是容易让人困惑：
“不是说值传递不会影响原数据吗？为什么 nums 还是变了？”
核心原因：切片值传递传的是「切片描述符（header）」，但 descriptor 里指向的底层数组是共享的。
因此即使形参是副本，副本里的 Data 指针仍指向同一块数组，原地修改元素会反映到外层。
一句话总结：
值传递 []int：能改元素（共享底层数组），不能改 len/cap。
指针传递 *[]int：既能改元素，也能改 len/cap（如 append 后赋值回）。*/
