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
	return fmt.Sprintf("\nVRFRequest{ \n\tID: %v, \n\tAssocID: %v, \n\tBlockNum: %v, \n\tBlockHash: %v, \n\tSeeds: %v, \n\tCount: %v, \n\tCaller: %v\n}",
		m.ID,
		m.AssocID,
		m.BlockNum,
		m.BlockHash,
		m.Seeds,
		m.Count,
		m.Caller,
	)
	// return fmt.Sprintf("\nVRFRequest{ \n\tID: %v, \n\tAssocID: %v, \n\tBlockNum: %v, \n\tBlockHash: %v, \n\tSeeds: %v, \n\tFrequency: %v, \n\tCount: %v, \n\tCaller: %v, \n\tType: %v, \n\tStatus: %v, \n\tStartAt: %v, \n\tEndAt: %v, \n\tCronID: %v, \n\tCreatedAt: %v, \n\tUpdatedAt: %v, \n\tDeletedAt: %v\n}",
	// 	m.ID,
	// 	m.AssocID,
	// 	m.BlockNum,
	// 	m.BlockHash,
	// 	m.Seeds,
	// 	m.Frequency,
	// 	m.Count,
	// 	m.Caller,
	// 	m.Type,
	// 	m.Status,
	// 	m.StartAt,
	// 	m.EndAt,
	// 	m.CronID,
	// 	m.CreatedAt,
	// 	m.UpdatedAt,
	// 	m.DeletedAt,
	// )
}
