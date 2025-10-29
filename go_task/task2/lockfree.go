package main


import (
	"fmt"
	"sync"
	"sync/atomic"
)

func main(){
	var counter int64

	var wg sync.WaitGroup


	//启动10个协程
	for i:=1;i<=10;i++ {
		wg.Add(1)
		go func(){
			//每个协程加1000次 
			defer wg.Done()
			for j:=0;j<1000;j++{
				//原子操作
				atomic.AddInt64(&counter,1)
			}
		}()
	}
	//不加可能出现不同的结果 随机的，表示提前执行atomic.LoadInt64(&counter)
	wg.Wait()
	fmt.Println("无锁最终结果:",atomic.LoadInt64(&counter))

}