package main

import (
	"fmt"
	"reflect"
	"time"
)


func main() {
	
	s1 :="abc1231"
	
	for index := range s1{
		fmt.Printf("s1 --- index:%d,value:%d\n",index,s1[index])
	}


    str2 := "测试中文"
    for index,r := range str2 {
        fmt.Printf("str2 -- index:%d, value:%d\n,r=%c", index, str2[index],r)
    }
    fmt.Printf("len(str2) = %d\n", len(str2))

    runesFromStr2 := []rune(str2)
    bytesFromStr2 := []byte(str2)
    fmt.Printf("len(runesFromStr2) = %d\n", len(runesFromStr2))
	fmt.Printf("len(bytesFromStr2) = %d\n", len(bytesFromStr2))
	fmt.Println("rune",runesFromStr2[1])

	array := [...]int{1, 2, 3}
    slice := []int{4, 5, 6}

    // 方法1：只拿到数组的下标索引
    for index := range array {
        fmt.Printf("array -- index=%d value=%d \n", index, array[index])
    }
    for index := range slice {
        fmt.Printf("slice -- index=%d value=%d \n", index, slice[index])
    }
    fmt.Println()

    // 方法2：同时拿到数组的下标索引和对应的值
    for index, value := range array {
        fmt.Printf("array -- index=%d index value=%d \n", index, array[index])
        fmt.Printf("array -- index=%d range value=%d \n", index, value)
    }
    for index, value := range slice {
        fmt.Printf("slice -- index=%d index value=%d \n", index, slice[index])
        fmt.Printf("slice -- index=%d range value=%d \n", index, value)
    }
	fmt.Println()
	
	array1 := [...][3]int{{1, 2, 3}, {4, 5, 6}}
    slice1 := [][]int{{1, 2}, {3}}
    // 只拿到行的索引
    for index := range array1 {
        // array[index]类型是一维数组
        fmt.Println(reflect.TypeOf(array1[index]))
        fmt.Printf("array1 -- index=%d, value=%v\n", index, array1[index])
    }

    for index := range slice1{
        // slice[index]类型是一维数组
        fmt.Println(reflect.TypeOf(slice1[index]))
        fmt.Printf("slice -- index=%d, value=%v\n", index, slice1[index])
    }

    // 拿到行索引和该行的数据
    fmt.Println("print array element")
    for row_index, row_value := range array1 {
        fmt.Println(row_index, reflect.TypeOf(row_value), row_value)
    }

    fmt.Println("print array slice")
    for row_index, row_value := range slice1 {
        fmt.Println(row_index, reflect.TypeOf(row_value), row_value)
    }

    // 双重遍历，拿到每个元素的值
    for row_index, row_value := range array1 {
        for col_index, col_value := range row_value {
            fmt.Printf("array[%d][%d]=%d ", row_index, col_index, col_value)
        }
        fmt.Println()
    }
    for row_index, row_value := range slice1 {
        for col_index, col_value := range row_value {
            fmt.Printf("slice[%d][%d]=%d ", row_index, col_index, col_value)
        }
        fmt.Println()
	}
	ch :=make(chan int,10)
	go addData(ch)

	for i :=range ch {
		fmt.Println(i)
	}
}

func addData(ch chan int){
	size :=cap(ch)
	for i :=0;i<size;i++{
		ch <-i
		time.Sleep(1*time.Second)
	}
	close(ch)
}
