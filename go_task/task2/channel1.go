package main

import (
	"fmt"
	"sync"
)

func main(){
	ch :=make(chan int)
	var wg sync.WaitGroup
	wg.Add(2)

	//产生数据
	go func(){
		defer wg.Done()
		for i:=1;i<=10;i++{
			ch <-i
		}
		close(ch)
	}()
	
	//接受数据
	 go func(){
		 // 防止 主函数提前退出
		defer wg.Done()
		 for c :=range ch{
			 fmt.Printf("接受数据:%v \n",c)
		 }
	 }()
	 wg.Wait()
	 
}