package main


import (
	"fmt"
	"math")

type Shape interface {
	Area()
	Perimeter()
}

type Rectangle struct{
	a int
	b int

}

type Circle struct{
   r int
}
// 长方形面积
func (r *Rectangle) Area() int {
	return r.a*r.b
}
//长方形周长
func (r *Rectangle) Perimeter() int {
	return 2*(r.a+r.b)
}

//圆形面积
func (c *Circle) Area() float64 {

	return math.Pi*(float64)(c.r)*(float64)(c.r)
}

//圆形周长
func (c *Circle) Perimeter() float64 {
	return 2*math.Pi*(float64)(c.r)
}

func main() {
	r := &Rectangle{a:4,b:5}
	c := &Circle{r:3}
	fmt.Printf(" 长方形，面积：%v,周长：%v \n",r.Area(),r.Perimeter())
	fmt.Printf(" 圆形，面积：%.4f,周长：%.4f \n",c.Area(),c.Perimeter())
}