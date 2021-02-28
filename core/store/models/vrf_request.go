package models

import (
	"time"

	null "gopkg.in/guregu/null.v4"
)

type VRFRequestType string

const (
	VRFRequestType_RECURRENT = "recurrent"
	VRFRequestType_SCHEDULED = "scheduled"
	VRFRequestType_IMMEDIATE = "immediate"
)

type VRFRequestStatus string

const (
	VRFRequestStatus_ACTIVE    = "Active"
	VRFRequestStatus_COMPLETED = "Completed"
)

//VRFRequest represents a vrf request
type VRFRequest struct {
	ID        uint64           `gorm:"primary_key;auto_increment"`
	AssocID   uint64           `gorm:"type:numeric(20);index;not null"`
	Seed      uint64           `gorm:"type:numeric(20);not null"`
	Frequency string           `gorm:"type:varchar(25);not null"`
	Count     uint8            `gorm:"not null"`
	Caller    string           `gorm:"type:varchar(15);index;not null"`
	Type      VRFRequestType   `gorm:"type:varchar(15);index;not null"`
	Status    VRFRequestStatus `gorm:"index; type:varchar(20)"`
	StartAt   null.Time        `gorm:"index"`
	EndAt     null.Time        `gorm:"index"`
	CronID    int
	CreatedAt time.Time `gorm:"not null"`
	UpdatedAt time.Time `gorm:"index"`
	DeletedAt null.Time `gorm:"index"`
}
