package task

import (
	"fmt"
	"log"
	"github.com/jmoiron/sqlx"
	_ "github.com/go-sql-driver/mysql"
)

type Employee struct{
	ID int `db:"id"`
	Name string `name:"id"`
	Department string `db:"department"`
	Salary float64 `db:"salary"`
}

type Book struct{
	ID int `db:"id"`
	Title string `db:"title"`
	Author string `db:"author"`
	Price float64 `db:"price"`
}

func Ex03()  {
		// 1. 连接数据库（mysql 示例）
		dsn := "root:530626kl@tcp(127.0.0.1:3306)/test?charset=utf8mb4&parseTime=True"
		db, err := sqlx.Connect("mysql", dsn)
		if err != nil {
			log.Fatal(err)
		}
		defer db.Close()

		// 查询技术部
		var emps []Employee
		err = db.Select(&emps, "SELECT id, name, department, salary FROM employees WHERE department = ?", "技术部")
		if err != nil {
			log.Fatal(err)
		}
		fmt.Println("技术部员工：", emps)
		//最高金额员工
		var topEmp Employee
		err = db.Get(&topEmp,"select id,name,department,salary from employees order by salary desc limit 1")
		if err != nil {
			log.Fatal(err)
		}
		fmt.Println("最高金额员工", topEmp)

		//查询价格大于 50 元的书籍

		var books []Book
		err = db.Select(&books,"select id ,title,author,price from books where price > 50 order by id desc")
		if err != nil {
			log.Fatal(err)
		}
		fmt.Println("查询价格大于50元的书籍")
		for _, s := range books {
			fmt.Printf("ID: %-2d 标题：%v 作者：%v 价格：%-3v\n",s.ID,s.Title, s.Author, s.Price)
		}
		
}