package main


import (
	"fmt"
	"strconv"
)

func main() {
	var i int32 = 17
	var b byte = 5
	var f float32

	  // 数字类型可以直接强转
	f = float32(i)/float32(b)
	fmt.Printf("f 的值为: %f\n", f)

	 // 当int32类型强转成byte时，高位被直接舍弃
	 var i2 int32 = 256
	 var b2 byte = byte(i2)
	 fmt.Printf("b2 的值为: %d\n", b2)
	 
	 fmt.Println()

	 str := "hello, 123, 你好"
	 var bytes []byte = []byte(str)
	 var runes []rune = []rune(str)
	 fmt.Printf("bytes 的值为: %v \n", bytes)
	 fmt.Printf("runes 的值为: %v \n", runes)
 
	 str2 := string(bytes)
	 str3 := string(runes)
	 fmt.Printf("str2 的值为: %v \n", str2)
	 fmt.Printf("str3 的值为: %v \n", str3)

	 str4 := "123"
	 num, err := strconv.Atoi(str4)
	 if err != nil {
		 panic(err)
	 }
	 fmt.Printf("字符串转换为int: %d \n", num)
	 str5 := strconv.Itoa(num)
	 fmt.Printf("int转换为字符串: %s \n", str5)
 
	 ui64, err := strconv.ParseUint(str5, 10, 32)
	 fmt.Printf("字符串转换为uint64: %d \n", ui64)
 
	 str6 := strconv.FormatUint(ui64, 2)
	 fmt.Printf("uint64转换为字符串: %s \n", str6)

	 fmt.Println()
	  var g interface{} = 3
	  a,ok :=g.(int)
	  if ok {
        fmt.Printf("'%d' is a int \n", a)
    } else {
        fmt.Println("conversion failed")
	}
	
	switch v := g.(type) {
    case int:
        fmt.Println("g is a int", v)
    case string:
        fmt.Println("g is a string", v)
    default:
        fmt.Println("g is unknown type", v)
    }
}