package main 


import "fmt"



type Person struct{
	Name string
	Age int
}

type Employee struct{
	Person  // 匿名嵌套
	EmployeeID int
}

func (e Employee) PrintInfo(){
	fmt.Printf("EmployeeID: %d, Name: %s, Age: %d\n",e.EmployeeID, e.Name, e.Age)
}


func main(){
	emp :=Employee{
		Person : Person{Name:"小王",Age:35},
		EmployeeID: 10,
	}
	 emp.PrintInfo()

}


