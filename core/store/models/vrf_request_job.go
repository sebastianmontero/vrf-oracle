package models

import (
	"time"

	null "gopkg.in/guregu/null.v4"
)

type VRFRequestJobStatus string

const (
	VRFRequestJobStatus_FAILED    = "Failed"
	VRFRequestJobStatus_ACTIVE    = "Active"
	VRFRequestJobStatus_RUNNING   = "Running"
	VRFRequestJobStatus_COMPLETED = "Completed"
)

//VRFRequestJob represents a vrf request job
type VRFRequestJob struct {
	ID           uint64 `gorm:"primary_key;auto_increment"`
	VRFRequestID uint64
	VRFRequest   *VRFRequest
	StartAt      time.Time           `gorm:"index"`
	EndAt        null.Time           `gorm:"index"`
	Status       VRFRequestJobStatus `gorm:"index; type:varchar(20)"`
	Retries      uint8
}
