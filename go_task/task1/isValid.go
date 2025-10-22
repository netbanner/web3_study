package main 

import "fmt"


func isValid( s string) bool{

	stack :=[]rune{}
	pairs := map[rune]rune{
        ')': '(',
        ']': '[',
        '}': '{',
    }

	for _,ch := range s{
		switch ch {
		case '(','[','{':
			stack = append(stack,ch) //左括号入栈
		case ')',']','}':
			if len(stack) == 0 || stack[len(stack)-1] != pairs[ch] {
                return false // 不匹配或栈空
            }
			stack = stack[:len(stack)-1] // 弹出栈顶
			fmt.Println("stack : ",stack)
		}
		
	}

	return len(stack) == 0 
}

func main(){

	s :="()"
	fmt.Println("有效的刮号:",isValid(s))

}