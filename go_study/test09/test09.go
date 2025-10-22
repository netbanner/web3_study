package main


import (
	"fmt"
	//"context"
	"time"
	//"sync/atomic"
)

func main() {
	//方式一
	for i:=0;i<10;i++{
		fmt.Println("方式1，第", i + 1,"次循环")
	}


 // 方式2
	b := 1
	for b < 10 {
		b++
		fmt.Println("方式2，第", b,"次循环")
	}

	//无限循环
	/* ctx,_ :=context.WithDeadline(context.Background(), time.Now().Add(time.Second*2))
	var started bool
	var stopped atomic.Bool
	for {
		if!started{
			started = true
			go func(){
				for {
					select {
					case <-ctx.Done():
						fmt.Println("ctx done")
						stopped.Store(true)
						return
					}
				}
			}()
		}
		fmt.Println("main")
		if stopped.Load(){
			break
		}
	}
 */
	//遍历数组
	var a [10]string
	a[0]  = "hello"
	for  i:= range a {
		fmt.Println("当前下标：", i)
	}

	for i,e := range a{
		fmt.Println("a[", i, "] = ", e)
	} 

	//遍历切片
	 s :=make([]string,10)
	 s[0] = "hello"
	 for  i:= range s {
		fmt.Println("当前下标：", i)
	}

	for i,e := range s{
		fmt.Println("s[", i, "] = ", e)
	} 

	 m :=make(map[string]string)
	 m["b"] = "Hello,b"
	 m["a"] = "Hello,a"
	 m["c"] = "Hello,c"
	 m["d"] = "Hello,d"

	 for i:=range m{
		 fmt.Println("当前key:",i)
	 }

	 for k, v := range m {
		fmt.Println("m[", k, "] = ", v)
	 }

	 fmt.Printf("------------ break 语句 ---- \n")

	 //中断for循环
	 for i := 0;i<5;i++{
		 if(i==3){
			 break
		 }
	 }

	 //中断switch
	 switch i:=1; i {
		case 1:
			fmt.Println("进入 case 1")
			if (i==1){
				break
			}
			fmt.Println("i=1")
		case 2:
			fmt.Println("i=2")
		default:
			fmt.Println("default case")
	 }

	 //中断select
	 select {
		case <-time.After(time.Second*2):
			fmt.Println("2秒")
		case <-time.After(time.Second):
			fmt.Println("1秒")
			if true{
				break
			}
			fmt.Println("break 之后")
	 }
	
	 // 不使用标记
	 for i :=1;i<=3;i++{
		fmt.Printf("不使用标记,外部循环, i = %d\n", i)
        for j := 5; j <= 10; j++ {
            fmt.Printf("不使用标记,内部循环 j = %d\n", j)
            break
        }
	 }

	 //使用标记
	 outter:
	 for i :=1;i<=3;i++{
		fmt.Printf("使用标记,外部循环, i = %d\n", i)
        for j := 5; j <= 10; j++ {
            fmt.Printf("使用标记,内部循环 j = %d\n", j)
            break outter
        }
	 }


	 fmt.Printf("--------- contine ----- \n")

	 for i:=0;i<5;i++{
		 if i==3 {
			 continue
		 }
		 fmt.Println("第",i,"次循环")
	 }
	//不使用标记
	 for i:= 1;i<=2 ;i++ {
		fmt.Printf("不使用标记,外部循环, i = %d\n", i)
        for j := 5; j <= 10; j++ {
            fmt.Printf("不使用标记,内部循环 j = %d\n", j)
            if j >= 7 {
                continue
            }
            fmt.Println("不使用标记，内部循环，在continue之后执行")
        }
	 }

	     // 使用标记
	outter2:
	for i := 1; i <= 3; i++ {
		fmt.Printf("使用标记,外部循环, i = %d\n", i)
		for j := 5; j <= 10; j++ {
			fmt.Printf("使用标记,内部循环 j = %d\n", j)
			if j >= 7 {
				continue outter2
			}
			fmt.Println("使用标记，内部循环，在continue之后执行")
		}
	}
}

