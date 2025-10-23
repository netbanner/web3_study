package main

import (
	"fmt"
	"sync"
)

func main(){

	//缓冲容量为10 
	ch :=make(chan int,10)
	var wg sync.WaitGroup
	wg.Add(2)

	//生产者
	go func(){
		defer wg.Done()
		for i:=1;i<=100;i++{
			ch <-i
			fmt.Printf("生产者:%v \n",i)
		}
		close(ch)
	}()
	
	//消费者
	 go func(){
		 // 防止 主函数提前退出
		defer wg.Done()
		 for c :=range ch{
			 fmt.Printf("消费者:%v \n",c)
		 }
	 }()
	 wg.Wait()
	 
}