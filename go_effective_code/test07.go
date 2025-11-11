package main

var sem = make(chan int, MaxOutstanding)

func handle(r *Request) {
    sem <- 1    // 等待活动队列清空。
    process(r)  // 可能需要很长时间。
    <-sem       // 完成；使下一个请求可以运行。
}

func Serve(queue chan *Request) {
    for {
        req := <-queue
        go handle(req)  // 无需等待 handle 结束。
    }
}

//修改
func Serve(queue chan *Request) {
    for req := range queue {
        sem <- 1
        go func() {
            process(req) // Buggy; see explanation below.
            <-sem
        }()
    }
}
/*
Bug 出现在 Go 的 for 循环中，该循环变量在每次迭代时会被重用，
因此 req 变量会在所有的 Go 协程间共享，这不是我们想要的。
我们需要确保 req 对于每个 Go 协程来说都是唯一的。有一种方法能够做到，就是将 req 的值作为实参传入到该 Go 协程的闭包中：
*/

func Serve(queue chan *Request) {
    for req := range queue {
        sem <- 1
        go func(req *Request) {
            process(req)
            <-sem
        }(req)
    }
}

func handle(queue chan *Request) {
    for r := range queue {
        process(r)
    }
}

func Serve(clientRequests chan *Request, quit chan bool) {
    // 启动处理程序
    for i := 0; i < MaxOutstanding; i++ {
        go handle(clientRequests)
    }
    <-quit  // 等待通知退出。
}


const numCPU = 4 // CPU 核心数

func (v Vector) DoAll(u Vector) {
    c := make(chan int, numCPU)  // 缓冲区是可选的，但明显用上更好
    for i := 0; i < numCPU; i++ {
        go v.DoSome(i*len(v)/numCPU, (i+1)*len(v)/numCPU, u, c)
    }
    // 排空信道。
    for i := 0; i < numCPU; i++ {
        <-c    // 等待任务完成
    }
    // 一切完成
}


//漏桶缓存区限流设计
var freeList = make(chan *Buffer, 100)
var serverChan = make(chan *Buffer)
//客户端
func client() {
    for {
        var b *Buffer
        // 若缓冲区可用就用它，不可用就分配个新的。
        select {
        case b = <-freeList:
            // 获取一个，不做别的。
        default:
            // 非空闲，因此分配一个新的。
            b = new(Buffer)
        }
        load(b)              // 从网络中读取下一条消息。
        serverChan <- b      // 发送至服务器。
    }
}

//服务端
func server() {
    for {
        b := <-serverChan    // 等待工作。
        process(b)
        // 若缓冲区有空间就重用它。
        select {
        case freeList <- b:
            // 将缓冲区放到空闲列表中，不做别的。
        default:
            // 空闲列表已满，保持就好。
        }
	}
	
}


