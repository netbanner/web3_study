package main


import (
	"fmt"
	"sync"
)
//共享计数器
type Counter struct{
	mu sync.Mutex
	n int64
}

func (c *Counter) Inc(){
	c.mu.Lock()
	c.n++
	c.mu.Unlock()
}

func (c *Counter) getVal() int64{
	c.mu.Lock()
	//保持 unlock最后执行
	defer c.mu.Unlock()
	return c.n
}

func main() {
	var wg sync.WaitGroup
	var counter Counter

	//启动10个协程
	for i:=1;i<=10;i++ {
		wg.Add(1)
		go func(){
			//每个协程加1000次
			defer wg.Done()
			for j:=0;j<1000;j++{
				counter.Inc()
			}
		}()
	}
	wg.Wait()
	fmt.Println("最后结果：",counter.getVal())
}

