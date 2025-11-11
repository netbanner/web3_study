package main


type ByteSlice []byte

func (slice ByteSlice) Append(data []byte) []byte {
    // 主体与上面定义的Append函数完全相同。
}

func (p *ByteSlice) Append(data []byte) {
    slice := *p
    // 主体同上，只是没有返回值
    *p = slice
}

func (p *ByteSlice) Write(data []byte) (n int, err error) {
    slice := *p
    // 同上。
    *p = slice
    return len(data), nil
}