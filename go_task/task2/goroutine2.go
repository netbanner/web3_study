package main


import (
	"fmt"
	"sync"
	"time"
)

//task
type Task struct{
	Name string
	Method func () 
}
// 指针时间
type Result struct {
	Name string
	Cost time.Duration
}

func Scheduler(tasks []Task) []Result  {
	ch :=make(chan Result, len(tasks))
	var wg sync.WaitGroup
	for _,t:=range tasks{
		wg.Add(1)
		go func (t Task)  {
			defer wg.Done()
			start :=time.Now()
			t.Method()
			//入
			ch <- Result{Name: t.Name,Cost:time.Since(start)}
		}(t)
	}
	wg.Wait()
	close(ch)
	 
	var results []Result
	for r:=range ch{
		results = append(results,r)
	}
	return results
}


func main() {
	tasks :=[]Task{
		{Name: "task-A", Method: func() { time.Sleep(100 * time.Millisecond) }},
		{Name: "task-B", Method: func() { time.Sleep(200 * time.Millisecond) }},
		{Name: "task-C", Method: func() { time.Sleep(150 * time.Millisecond) }},
		{Name: "task-D", Method: func() { time.Sleep(300 * time.Millisecond) }},
		{Name: "task-E", Method: func() { time.Sleep(400 * time.Millisecond) }},
		{Name: "task-F", Method: func() { time.Sleep(550 * time.Millisecond) }},
	}
	results :=Scheduler(tasks)

	for _,r :=range results{
		fmt.Printf("%s cost: %v\n", r.Name, r.Cost)
	}
}