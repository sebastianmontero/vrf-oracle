package models

import (
	"fmt"
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

func NewVRFRequestJob(req *VRFRequest) *VRFRequestJob {
	return &VRFRequestJob{
		VRFRequestID: req.ID,
		VRFRequest:   req,
		StartAt:      time.Now(),
		Status:       VRFRequestJobStatus_ACTIVE,
		Retries:      0,
	}
}

func (m *VRFRequestJob) UpdateStatus(runStatus VRFRequestRunStatus, maxRetries uint8) {
	switch runStatus {
	case VRFRequestRunStatus_RUNNING:
		m.Status = VRFRequestJobStatus_RUNNING
	case VRFRequestRunStatus_COMPLETED:
		m.EndAt = null.NewTime(time.Now(), true)
		m.Status = VRFRequestJobStatus_COMPLETED
	case VRFRequestRunStatus_FAILED:
		m.Retries++
		if m.Retries > uint8(maxRetries) {
			m.EndAt = null.NewTime(time.Now(), true)
			m.Status = VRFRequestJobStatus_FAILED
		} else {
			m.Status = VRFRequestJobStatus_ACTIVE
		}
	}
	m.VRFRequest.UpdateStatus(m.Status)
}

func (m *VRFRequestJob) String() string {
	return fmt.Sprintf("VRFRequestJob{ ID: %v, VRFRequestID: %v, VRFRequest: %v, StartAt: %v, EndAt: %v, Status: %v, Retries: %v",
		m.ID,
		m.VRFRequestID,
		m.VRFRequest,
		m.StartAt,
		m.EndAt,
		m.Status,
		m.Retries,
	)
}
