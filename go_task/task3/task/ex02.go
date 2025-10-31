package task

import (
	"fmt"
	"gorm.io/gorm"
	"errors"
	"log"
)

type Account struct{
	gorm.Model
	Balance uint64
}

type Transaction struct{
	gorm.Model
	FromAccountID uint
	ToAccountID uint
	Amount uint64
}

func Transfer(db *gorm.DB,fromID,toID uint,amount uint64) error{
	return db.Transaction(func(tx *gorm.DB) error {
		var fromA ,fromB Account
		fmt.Println("开始转帐")
		//1.获取 A账户
		tx.First(&fromA,fromID)
		//2. 判断A账户
		if fromA.Balance <amount{
			return errors.New("余额不足")
		}

		//获取 B账户
		tx.First(&fromB,toID)

		// 3. A扣款
		if err :=tx.Model(&fromA).Update("balance",fromA.Balance-amount).Error;err!=nil{
			return err
		}

		// B加款
		if err :=tx.Model(&fromB).Update("balance",fromB.Balance+amount).Error;err!=nil{
			return err
		}


		// 4. 写交易记录
		txn := Transaction{
			FromAccountID: fromID,
			ToAccountID:   toID,
			Amount:        amount,
		}
		return tx.Create(&txn).Error
	})
		
}

func Ex02(db *gorm.DB){
	db.AutoMigrate(&Account{},&Transaction{})

	//db.Create(&Account{ Balance: 1000})
	//db.Create(&Account{ Balance: 500})

	// 执行转账
	if err := Transfer(db, 1, 2, 100); err != nil {
		log.Println("转账失败:", err)
	} else {
		log.Println("转账成功")
	}
}

