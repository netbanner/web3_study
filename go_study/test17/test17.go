package main

import "fmt"

// PaymentMethod 接口定义了支付方法的基本操作
type PayMethod interface {
	Pay(amount int) bool
	Account
}

type Account interface{
	GetBalance() int
}

type CreditCard struct {
	balance int
	limit int
}
// CreditCard 结构体实现 PaymentMethod 接口
func (c *CreditCard) Pay(amount int) bool  {
	if(c.balance+amount<c.limit){
		c.balance +=amount
		fmt.Printf("信用卡支付成功: %d\n", amount)
        return true
	}
	fmt.Println("信用卡支付失败: 超出额度")
    return false
}

func (c *CreditCard) GetBalance() int  {
	return c.balance	
}

// DebitCard 结构体实现 PaymentMethod 接口
type DebitCard struct {
    balance int
}

func (d *DebitCard) Pay(amount int) bool  {
	if d.balance >= amount {
        d.balance -= amount
        fmt.Printf("借记卡支付成功: %d\n", amount)
        return true
    }
    fmt.Println("借记卡支付失败: 余额不足")
    return false
}

func (d *DebitCard) GetBalance() int {
    return d.balance
}

func purchaseItem(p PayMethod,price int)  {
	if(p.Pay(price)){
		if p.Pay(price) {
			fmt.Printf("购买成功，剩余余额: %d\n", p.GetBalance())
		} else {
			fmt.Println("购买失败")
		}
	}
}

func anyParam(param interface{}) {
    fmt.Println("param: ", param)
}

func main(){
	creditCard :=&CreditCard{balance:0,limit:1000}
	debitCard :=&DebitCard{balance:500}
	fmt.Println("使用信用卡购买:")
    purchaseItem(creditCard, 800)

    fmt.Println("\n使用借记卡购买:")
    purchaseItem(debitCard, 300)

    fmt.Println("\n再次使用借记卡购买:")
	purchaseItem(debitCard, 300)
	
	c := CreditCard{balance: 100, limit: 1000}
    c.Pay(200)
    var a PayMethod = &c
    fmt.Println("a.Pay: ", a)

    var b interface{} = &c
    fmt.Println("b: ", b)

    anyParam(c)
    anyParam(1)
    anyParam("123")
    anyParam(a)
}