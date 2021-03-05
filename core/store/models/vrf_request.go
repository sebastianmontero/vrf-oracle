package models

import (
	"fmt"
	"time"

	"github.com/lib/pq"
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
	BlockNum  uint64           `gorm:"type:numeric(20);not null"`
	BlockHash string           `gorm:"type:varchar(70);not null"`
	Seeds     pq.StringArray   `gorm:"type:varchar(70)[];not null"`
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

func (m *VRFRequest) UpdateStatus(jobStatus VRFRequestJobStatus) {
	switch jobStatus {
	case VRFRequestJobStatus_COMPLETED, VRFRequestJobStatus_FAILED:
		if m.Type == VRFRequestType_IMMEDIATE || m.Type == VRFRequestType_SCHEDULED {
			m.Status = VRFRequestStatus_COMPLETED
		}
	}
}

func (m *VRFRequest) String() string {
	return fmt.Sprintf("VRFRequest{ ID: %v, AssocID: %v, BlockNum: %v, BlockHash: %v, Seeds: %v, Frequency: %v, Count: %v, Caller: %v, Type: %v, Status: %v, StartAt: %v, EndAt: %v, CronID: %v, CreatedAt: %v, UpdatedAt: %v, DeletedAt: %v",
		m.ID,
		m.AssocID,
		m.BlockNum,
		m.BlockHash,
		m.Seeds,
		m.Frequency,
		m.Count,
		m.Caller,
		m.Type,
		m.Status,
		m.StartAt,
		m.EndAt,
		m.CronID,
		m.CreatedAt,
		m.UpdatedAt,
		m.DeletedAt,
	)
}
