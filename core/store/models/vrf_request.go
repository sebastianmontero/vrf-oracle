package models

import (
	"time"

	null "gopkg.in/guregu/null.v4"
)

//VRFRequest represents a vrf request
type VRFRequest struct {
	ID          uint64    `gorm:"primary_key;auto_increment"`
	AssocID     uint64    `gorm:"type:numeric(20);index;not null"`
	Seed        uint64    `gorm:"type:numeric(20);not null"`
	Frequency   string    `gorm:"type:varchar(25);not null"`
	Count       uint8     `gorm:"not null"`
	Caller      string    `gorm:"type:varchar(15);index;not null"`
	StartAt     time.Time `gorm:"index"`
	EndAt       time.Time `gorm:"index"`
	StartCronID int
	EndCronID   int
	CronID      int
	CreatedAt   time.Time `gorm:"not null"`
	UpdatedAt   time.Time `gorm:"index"`
	DeletedAt   null.Time `gorm:"index"`
}
