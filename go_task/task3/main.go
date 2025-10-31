package main

import (
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"task3/task"
	"fmt"
)

func InitDb(dst ...interface{}) *gorm.DB {
	db, err := gorm.Open(mysql.Open("root:530626kl@tcp(127.0.0.1:3306)/gorm?charset=utf8mb4&parseTime=True&loc=Local"))
	if err != nil {
		panic(err)
	}

	db.AutoMigrate(dst...)

	return db
}

func main()  {
	//db :=InitDb()
	//task.Ex01(db)
	fmt.Println("--------")
	
	//task.Ex02(db)

	task.Ex03()
}