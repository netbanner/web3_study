package task

import (
	"fmt"
	"gorm.io/gorm"
)

type Student struct {
	gorm.Model
	Name string 
	Age uint
	Grade string
}


func Ex01(db *gorm.DB)  {
	fmt.Printf("ex01:\n")
	db.AutoMigrate(&Student{})

 //	stu :=Student{Name:"张三",Age:20,Grade:"三年级"}
//	db.Create(&stu)
	
	db.Model(&Student{}).Where("name = ?", "张三").
	Update("grade", "四年级")

	stus :=[]Student{}
	db.Debug().Find(&stus,"age > ? ",18)
	fmt.Println("大于18岁的学生信息：")
	for _, s := range stus {
		fmt.Printf("姓名：%-6s 年龄：%-2d 年级：%-3s\n", s.Name, s.Age, s.Grade)
	}
	//编写SQL语句删除 students 表中年龄小于 15 岁的学生记录。
	db.Debug().Where(" age < ? ",15).Delete(&Student{})
}