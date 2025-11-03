package task

import (
	"fmt"
	"gorm.io/gorm"
)

type User struct {
	gorm.Model
	Name string
	Age uint
	Posts []Post `gorm:"foreignKey:UserID;references:ID"`
	PostCount int8 `gorm:"default:0"`
}

type Post struct{
	gorm.Model
	UserID uint
	Title string
	Content string
	Comments []Comment `gorm:"foreignKey:PostID;references:ID"`
	CmtStatus  string    `gorm:"default:'有评论'"` 

}

type Comment struct{
	gorm.Model
	Content string
	PostID uint 
}
//创建文章时
func (p *Post) AfterCreate(db *gorm.DB) error {
	return db.Model(&User{}).
		Where("id = ?", p.UserID).
		UpdateColumn("post_count", gorm.Expr("post_count + 1")).Error
		
}

//在评论删除时检查文章的评论数量，如果评论数量为 0，则更新文章的评论状态为 "无评论"。
func (c *Comment) AfterDelete(db *gorm.DB) error  {
	var cnt int64 // ✅ 用 int64
	
	if err :=db.Model(&Comment{}).
	Where("comments.post_id = ?",c.PostID).
	Count(&cnt).Error;err!=nil{
		return nil
	}
	if cnt==0 {
	  return db.Model(&Post{}).
		Where("id = ?",c.PostID).
		UpdateColumn("cmt_status","无评论").Error
	}
	return nil
	
}


func Ex04(db *gorm.DB)  {


	fmt.Printf("某个用户发布的所有文章及其对应的评论信息。")
	//某个用户发布的所有文章及其对应的评论信息。
	var user User
	db.Preload("Posts.Comments").First(&user,1)

	for _, p := range user.Posts {
		fmt.Printf("  文章：《%s》 评论数：%d 状态：%s\n", p.Title, len(p.Comments),p.CmtStatus)
		for _, c := range p.Comments {
			fmt.Printf("    评论：%s  \n", c.Content)
		}
	}

	// ======== 题目2.2 评论最多的文章 ========

	fmt.Printf("评论最多的文章。")

	var maxPost Post

	db.Model(&Post{}).
	Select("posts.*, COUNT(comments.id) as cnt").
	Joins("LEFT JOIN comments ON posts.id = comments.post_id").
	Group("posts.id").
	Order("cnt DESC").
	Limit(1).
	Scan(&maxPost)

	db.Preload("Comments").First(&maxPost,maxPost.ID)
	fmt.Printf("\n评论最多的文章：《%s》 评论数：%d\n", maxPost.Title, len(maxPost.Comments))
	
}


// 造数据
func Seed(db *gorm.DB) {

	fmt.Printf("ex04:\n")
	db.AutoMigrate(&User{},&Post{},&Comment{})

	u := User{Name: "JKafe"}
	db.Create(&u)

	p1 := Post{Title: "GORM 入门4", Content: "内容1", UserID: u.ID}
	p2 := Post{Title: "Go 并发5", Content: "内容5", UserID: u.ID}
	db.Create(&p1)
	db.Create(&p2)

	db.Create([]Comment{
		{Content: "写得好！", PostID: p1.ID},
		{Content: "学到了", PostID: p1.ID},
		{Content: "顶", PostID: p2.ID},
		{Content: "顶", PostID: p2.ID},
		{Content: "顶3", PostID: p2.ID},
		{Content: "顶3", PostID: p2.ID},
	})
}