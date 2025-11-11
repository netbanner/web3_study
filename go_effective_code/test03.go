package main



//初始化

// 常量 Go 中的常量就是不变量
type ByteSize float64

const {
	_ = iota 
	KB ByteSize  = 1<<(10*iota)
	MB
	GB 
	TB
	PB
	EB
	ZB
	YB
}


func (b ByteSize) String() string {

	switch  {
	case b >=YB :
		return fmt.Sprintf("%.2fYB", b/YB)
	}
	case b >=ZB :
		return fmt.Sprintf("%.2fYB", b/ZB)
	}
	case b >=EB :
		return fmt.Sprintf("%.2fYB", b/EB)
	}
	case b >=PB :
		return fmt.Sprintf("%.2fYB", b/PB)
	}
	case b >=TB :
		return fmt.Sprintf("%.2fYB", b/TB)
	}
	case b >=GB :
		return fmt.Sprintf("%.2fYB", b/GB)
	}
	case b >=MB :
		return fmt.Sprintf("%.2fYB", b/MB)
	}
	case b >=KB :
		return fmt.Sprintf("%.2fYB", b/KB)
	}
	return fmt.Sprintf("%.2fB", b)	
}

func init() {
    if user == "" {
        log.Fatal("$USER not set")
    }
    if home == "" {
        home = "/home/" + user
    }
    if gopath == "" {
        gopath = home + "/go"
    }
    // gopath 可通过命令行中的 --gopath 标记覆盖掉。
    flag.StringVar(&gopath, "gopath", gopath, "override default GOPATH")
}
