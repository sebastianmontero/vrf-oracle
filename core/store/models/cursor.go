package models

//CursorID represents a cursor Id
type CursorID string

const (
	CursorID_VRF_REQUESTS CursorID = "vrf-requests"
)

//Cursor represents the cursor returned by firehose
type Cursor struct {
	ID     CursorID `gorm:"primary_key;varchar(20)"`
	Cursor string   `gorm:"type:varchar(200);not null"`
}
