package main


//recover
func server(workChan <-chan *Work) {
    for work := range workChan {
        go safelyDo(work)
    }
}

func safelyDo(work *Work) {
    defer func() {
        if err := recover(); err != nil {
            log.Println("work failed:", err)
        }
    }()
    do(work)
}



// Error 是解析错误的类型，它满足 error 接口。
type Error string
func (e Error) Error() string {
    return string(e)
}

// error 是 *Regexp 的方法，它通过用一个 Error 
// 触发Panic来报告解析错误。
func (regexp *Regexp) error(err string) {
    panic(Error(err))
}

// Compile 返回该正则表达式解析后的表示。
func Compile(str string) (regexp *Regexp, err error) {
    regexp = new(Regexp)
    // 当发生解析错误时，doParse 会触发 panic
    defer func() {
        if e := recover(); e != nil {
            regexp = nil    // 清理返回值。
            err = e.(Error) // 若它不是解析错误，将重新触发Panic。
        }
    }()
    return regexp.doParse(str), nil
}

