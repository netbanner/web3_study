package main

// 表达式解析失败后返回错误代码
var (
    ErrInternal      = errors.New("regexp: internal error")
    ErrUnmatchedLpar = errors.New("regexp: unmatched '('")
    ErrUnmatchedRpar = errors.New("regexp: unmatched ')'")
    ...
)

var (
    countLock   sync.Mutex
    inputCount  uint32
    outputCount uint32
    errorCount  uint32
)
// 不能把左大括号放在下一行
if i < f() {
    g()
}

if x>0 {
	return y
}

if err :=file.Chmod(0664);err!=nil{
	log.Print(err)
	return err
}

sum := 0
for i := 0; i < 10; i++ {
    sum += i
}

for key, value := range oldMap {
    newMap[key] = value
}

for key := range m {
    if key.expired() {
        delete(m, key)
    }
}

sum := 0
for _, value := range array {
    sum += value
}

//应采用平行赋值的方式
// Reverse a
for i, j := 0, len(a)-1; i < j; i, j = i+1, j-1 {
    a[i], a[j] = a[j], a[i]
}

func unhex(c byte) byte {
    switch {
    case '0' <= c && c <= '9':
        return c - '0'
    case 'a' <= c && c <= 'f':
        return c - 'a' + 10
    case 'A' <= c && c <= 'F':
        return c - 'A' + 10
    }
    return 0
}

func shouldEscape(c byte) bool {
    switch c {
    case ' ', '?', '&', '=', '#', '+', '%':
        return true
    }
    return false
}

Loop:
    for n := 0; n < len(src); n += size {
        switch {
        case src[n] < sizeOne:
            if validateOnly {
                break
            }
            size = 1
            update(src[n])

        case src[n] < sizeTwo:
            if n+1 >= len(src) {
                err = errShortInput
                break Loop
            }
            if validateOnly {
                break
            }
            size = 2
            update(src[n] + src[n+1]<<shift)
        }
	}
	
	// 比较两个字节型切片，返回一个整数
// 按字典顺序.
// 如果a == b，结果为0；如果a < b，结果为-1；如果a > b，结果为+1
func Compare(a, b []byte) int {
    for i := 0; i < len(a) && i < len(b); i++ {
        switch {
        case a[i] > b[i]:
            return 1
        case a[i] < b[i]:
            return -1
        }
    }
    switch {
    case len(a) > len(b):
        return 1
    case len(a) < len(b):
        return -1
    }
    return 0
}

//类型选择
var t interface{}
t = functionOfSomeType()
switch t := t.(type) {
default:
    fmt.Printf("unexpected type %T\n", t)     // %T 打印任何类型的 t
case bool:
    fmt.Printf("boolean %t\n", t)             // t 是 bool 类型
case int:
    fmt.Printf("integer %d\n", t)             // t 是 int 类型
case *bool:
    fmt.Printf("pointer to boolean %t\n", *t) // t 是 *bool 类型
case *int:
    fmt.Printf("pointer to integer %d\n", *t) // t 是 *int 类型
}

//多个返回值    
func nextInt(b []byte, i int) (int, int) {
    for ; i < len(b) && !isDigit(b[i]); i++ {
    }
    x := 0
    for ; i < len(b) && isDigit(b[i]); i++ {
        x = x*10 + int(b[i]) - '0'
    }
    return x, i
}

func ReadFull(r Reader, buf []byte) (n int, err error) {
    for len(buf) > 0 && err == nil {
        var nr int
        nr, err = r.Read(buf)
        n += nr
        buf = buf[nr:]
    }
    return
}

// 内容返回文件的内容作为字符串。
func Contents(filename string) (string, error) {
    f, err := os.Open(filename)
    if err != nil {
        return "", err
    }
    defer f.Close()  // 我们结束后就关闭了f

    var result []byte
    buf := make([]byte, 100)
    for {
        n, err := f.Read(buf[0:])
        result = append(result, buf[0:n]...) // append稍后讨论。
        if err != nil {
            if err == io.EOF {
                break
            }
            return "", err  // 如果我们回到这里，f就关闭了。
        }
    }
    return string(result), nil // 如果我们回到这里，f就关闭了。
}

//被推迟的函数按照后进先出（LIFO）的顺序执行，因此以上代码在函数返回时会打印 4 3 2 1 0。
for i := 0; i < 5; i++ {
    defer fmt.Printf("%d ", i)
}

func trace(s string) string {
    fmt.Println("entering:", s)
    return s
}

func un(s string) {
    fmt.Println("leaving:", s)
}

func a() {
    defer un(trace("a"))
    fmt.Println("in a")
}

func b() {
    defer un(trace("b"))
    fmt.Println("in b")
    a()
}

func main() {
    b()
}
//结果：
/*
entering: b
in b
entering: a
in a
leaving: a
leaving: b
*/