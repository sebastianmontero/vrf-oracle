package models

import "fmt"

//CursorID represents a cursor Id
type CursorID string

const (
	CursorID_VRF_REQUESTS CursorID = "vrf-requests"
)

//Cursor represents the cursor returned by firehose
type Cursor struct {
	ID     CursorID `gorm:"primary_key;varchar(20)"`
	Cursor string   `gorm:"type:varchar(1000);not null"`
}

func (m *Cursor) String() string {
	return fmt.Sprintf("\nCursor{ \n\tID: %v, \n\tCursor: %v \n}", m.ID, m.Cursor)
}
