package main

const a int =1

const b = "test"

const c,d = 2,"hello"

const e,f bool = true,false

const (
	h byte = 3
	i = "value"
	j,k = "v",4
	l,m = 5,false
)

const (
	n = 6
)

const (
	Male = "Male"
	Female = "Female"
)

type Gender string

const (
	Male Gender = "Male"
	Female Gender = "Female"
)

func method(gender Gender) {}

func (g *Gender) String string{
	switch *g {
	case Male:
		return "Male"
	case Female:
        return "Female"
    default:
        return "Unknown"
    }
	}

}

func (g *Gender) IsMale() bool {
    return *g == Male
}

const pre int =1
const a int = iota

const (
	a int = iota
	c
	d
	e
)

const (
	f = 2
	g = iota
	h
	i
)