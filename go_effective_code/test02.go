package main

import (
	"sync"
)


//使用 new 关键字分配内存
//它不会 初始化 内存，只会将内存 置零。 也就是说，new(T) 会为类型为 T 的新项分配已置零的内存空间
//， 并返回它的地址，也就是一个类型为 *T 的值


type SyncedBuffer struct {
	lockd sync.Mutex
	buffer bytes.Buffer
}

p := new(SyncedBuffer)  // type *SyncedBuffer
var v SyncedBuffer      // type  SyncedBuffer


func NewFile2(fd int,name string) *File  {
		if fd <0{
			return nil
		}
		f :=new(File)
		f.fd =fd
		f.name =name
		f.dirinfo = nil
		f.nepipe =0
		return f
}
//返回一个局部变量的地址完全没有问题
func NewFile1(fd int, name string) *File {
    if fd < 0 {
        return nil
    }
    f := File{fd, name, nil, 0}
    return &f
}

//数组用法
func Sum(a *[3]float64) (sum float64) {
    for _, v := range *a {
        sum += v
    }
    return
}

array := [...]float64{7.0, 8.5, 9.1}
x := Sum(&array)  // Note the explicit address-of operator


var n int
var err error
for i := 0; i < 32; i++ {
	nbytes, e := f.Read(buf[i:i+1])  // Read one byte.
	n += nbytes
	if nbytes == 0 || e != nil {
		err = e
		break
	}
}
// 切片新增
func Append(slice, data []byte) []byte {
    l := len(slice)
    if l + len(data) > cap(slice) {  // 重新分配
        // 为未来的增长,双重分配所需的内容.
        newSlice := make([]byte, (l+len(data))*2)
        // copy函数是预先声明的，适用于任何切片类型。
        copy(newSlice, slice)
        slice = newSlice
    }
    slice = slice[0:l+len(data)]
    copy(slice[l:], data)
    return slice
}

//分配切片 二维切片

picture :=make([][]uint8,100) //每一行的大小
//循环遍历每一行
for i :=range picture{
	picture[i] = make([]uint8,100)
}

// 分配底层切片
picture := make([][]uint8, 100) //  每 y 个单元一行。
// 分配一个大一些的切片以容纳所有的元素
pixels := make([]uint8,100*100) // 指定类型[]uint8, 即便图片是 [][]uint8.
//循环遍历图片所有行，从剩余像素切片的前面对每一行进行切片。
for i := range picture {
    picture[i], pixels = pixels[:100], pixels[100:]
}

//打印
type T struct {
    a int
    b float64
    c string
}
t := &T{ 7, -2.35, "abc\tdef" }
fmt.Printf("%v\n", t) 
fmt.Printf("%+v\n", t) //%+v 为结构体加添加字段名
fmt.Printf("%#v\n", t)  //%#v 将完全按照 Go 的语法打印值
fmt.Printf("%#v\n", timeZone)
/**
&{7 -2.35 abc   def}
&{a:7 b:-2.35 c:abc     def}
&main.T{a:7, b:-2.35, c:"abc\tdef"}
map[string]int{"CST":-21600, "EST":-18000, "MST":-25200, "PST":-28800, "UTC":0}
*/

//打印值类型 map[string]int
fmt.Printf("%T\n", timeZone)
//自定义打印类型
func (t *T) String() string {
    return fmt.Sprintf("%d/%g/%q", t.a, t.b, t.c)
}
fmt.Printf("%v\n", t)



type MyString string
func (m MyString) String() string {
    return fmt.Sprintf("MyString=%s", string(m)) // 可以：注意转换
}

//Append 那样将一个切片追加到另一个切片
x := []int{1,2,3}
y := []int{4,5,6}
x = append(x, y...)
fmt.Println(x)