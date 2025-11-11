package main

// 接口与其它类型

import (
	"fmt"
	"sort"
)

type Sequence []int

func (s Sequence) Len() int  {
	return len(s)
}

func (s Sequence) Less(i,j int) bool  {
	return s[i]<s[j]
}

func (s Sequence) Swap(i,j int)  {
	
	s[i],s[j] = s[j],s[i]
}

func (s Sequence) Copy() Sequence{
	copy :=make(Sequence,0,len(s))
	return append(copy, s...)
}

func (s Sequence) String() string{
	s = s.Copy()
	sort.Sort(s)

	str :="["
	for i,elem :=range s{
		if i>0{
			str +=" "
		}
		str +=fmt.Sprint(elem)
	}

	return str +"]"
}

func (s Sequence) String() string {
    s = s.Copy()
    sort.Sort(s)
    return fmt.Sprint([]int(s))
}


// 打印方法-在打印之前对元素进行排序
func (s Sequence) String() string {
    s = s.Copy()
    sort.IntSlice(s).Sort()
    return fmt.Sprint([]int(s))
}


//接口转换与类型断言

type Stringer interface {
	String() string
}

var v interface{}
switch str := value.(type) {
case string:
    return str
case Stringer:
    return str.String()
}

str, ok := value.(string)
if ok {
    fmt.Printf("string value is: %q\n", str)
} else {
    fmt.Printf("value is not a string\n")
}

//接口及其类型
