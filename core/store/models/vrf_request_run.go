package models

import (
	"fmt"
	"time"

	null "gopkg.in/guregu/null.v4"
)

type VRFRequestRunStatus string

const (
	VRFRequestRunStatus_FAILED    = "Failed"
	VRFRequestRunStatus_RUNNING   = "Running"
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
	StatusMsg       string              `gorm:"index; type:text"`
}

func NewVRFRequestRun(vrfRequestJob *VRFRequestJob) *VRFRequestRun {
	vrfRequestJob.UpdateStatus(VRFRequestRunStatus_RUNNING, 0)
	return &VRFRequestRun{
		VRFRequestJobID: vrfRequestJob.ID,
		VRFRequestJob:   vrfRequestJob,
		StartAt:         time.Now(),
		Status:          VRFRequestRunStatus_RUNNING,
	}
}

func (m *VRFRequestRun) UpdateStatus(status VRFRequestRunStatus, msg string, maxRetries uint8) {
	m.EndAt = null.NewTime(time.Now(), true)
	m.Status = status
	m.StatusMsg = msg
	m.VRFRequestJob.UpdateStatus(status, maxRetries)
}

func (m *VRFRequestRun) String() string {
	return fmt.Sprintf("VRFRequestRun{ ID: %v, VRFRequestJobID: %v, VRFRequestJob: %v, StartAt: %v, EndAt: %v, Status: %v, StatusMsg: %v",
		m.ID,
		m.VRFRequestJobID,
		m.VRFRequestJob,
		m.StartAt,
		m.EndAt,
		m.Status,
		m.StatusMsg,
	)
}
