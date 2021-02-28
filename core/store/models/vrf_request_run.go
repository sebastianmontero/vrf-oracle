package models

import (
	"time"

	null "gopkg.in/guregu/null.v4"
)

type VRFRequestRunStatus string

const (
	VRFRequestRunStatus_FAILED    = "Failed"
	VRFRequestRunStatus_COMPLETED = "Completed"
)

//VRFRequestRun represents a vrf request run
type VRFRequestRun struct {
	ID              uint64 `gorm:"primary_key;auto_increment"`
	VRFRequestJobID uint64
	VRFRequestJob   *VRFRequestJob
	StartAt         time.Time           `gorm:"index"`
	EndAt           null.Time           `gorm:"index"`
	Status          VRFRequestRunStatus `gorm:"index; type:varchar(20)"`
	StatusMsg       string
}
