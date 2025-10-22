package main


import "fmt"


func plusOne(digits []int) []int {
    for  i := len(digits)-1;i>=0;i--{
        digits[i] +=1
        digits[i] %=10
        if digits[i]!=0{
            return digits
        }
    }
    return append([]int{1},digits...)
}

func main(){
	digits := []int{9,9,9,9}
	fmt.Println(plusOne(digits))
}