package main


import (
	"fmt"
)


func main()  {

	// 十六进制 以0xF/0xf 开头
var a uint8 = 0xFA
var b uint8 = 0xfB

// 八进制 以下开头
var c uint8 = 0173
var d uint8 = 0o174
var e uint8 = 0O177

// 二进制 以0b/0B开头
var f uint8 = 0b11111
var g uint8 = 0B11110

// 十进制
var h uint8 = 15

fmt.Println("a=",a)
fmt.Println("b=",b)
fmt.Println("c=",c)
fmt.Println("d=",d)
fmt.Println("e=",e)
fmt.Println("f=",f)
fmt.Println("g=",g)
fmt.Println("h=",h)

fmt.Println("---------------")

var float1 float32 = 10
float2 := 10.0
fmt.Println("float1=",float1)
fmt.Println("float2=",float2)

fmt.Println("---------------")
var c1 complex64
c1 = 1.10 + 0.1i
c2 := 1.10 + 0.1i
c3 := complex(1.10, 0.1) // c2与c3是等价的

x := real(c2)
y := imag(c2)

fmt.Println("c1=,",c1)
fmt.Println("c2=,",c2)
fmt.Println("c3=,",c3)
fmt.Println("x=,",x)
fmt.Println("y=,",y)

fmt.Println("---------------")

var s string = "hello world"
var bytes []byte = []byte(s)
fmt.Println("convert \"Hello, world!\" to bytes: ", bytes)

var bytes2 []byte = []byte{72, 101, 108, 108, 111, 44, 32, 119, 111, 114, 108, 100, 33}
var s2 string = string(bytes2)
fmt.Println(s2)


fmt.Println("-------- rune -------")
var r1 rune = 'a'
var r2 rune = '周'

fmt.Println("r1=",r1)
fmt.Println("r2=",r2)

var str string = "abc，你好，世界！"
var runes []rune = []rune(str)
fmt.Println("runes=",runes)


fmt.Println("-------- string -------")
var s5 string = "Hello\nworld!\n"
var s6 string = `Hello
world!
`
fmt.Println("s5=",s5)
fmt.Println("s6=",s6)
fmt.Println(s5 == s6)

var s7 string = "GO语言"
var bytes3 []byte = []byte(s7)
var runes1 []rune = []rune(s7)
fmt.Println("string length: ", len(s7))
fmt.Println("bytes length: ", len(bytes3))

//rune 是以字符个数为长度
fmt.Println("runes length: ", len(runes1))


fmt.Println("string sub: ", s7[0:7])
fmt.Println("bytes sub: ", string(bytes3[0:7]))
fmt.Println("runes sub: ", string(runes1[0:3]))

}