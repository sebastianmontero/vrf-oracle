package dtos

import (
	"fmt"
	"strconv"
	"strings"

	"github.com/sebastianmontero/vrf-oracle/core/store/models"
)

//Required becuase sometimes unit64 is sent as string
type STRING string

func (m *STRING) UnmarshalJSON(b []byte) error {
	*m = STRING(strings.ReplaceAll(string(b), `"`, ""))
	return nil
}

//Required becuase sometimes unit64 is sent as string
type UINT64 uint64

func (m *UINT64) UnmarshalJSON(b []byte) error {
	v, err := strconv.ParseUint(strings.ReplaceAll(string(b), `"`, ""), 10, 64)
	if err != nil {
		return err
	}
	*m = UINT64(v)
	return nil
}

type VRFChainJob struct {
	AssocID     UINT64   `json:"assoc_id,omitempty"`
	Seeds       []STRING `json:"seeds,omitempty"`
	CreatedDate string   `json:"created_date,omitempty"`
	BlockNum    uint64
	BlockHash   string
	Caller      string
}

func (m *VRFChainJob) VRFRequest() *models.VRFRequest {
	return &models.VRFRequest{
		AssocID:   uint64(m.AssocID),
		BlockNum:  m.BlockNum,
		BlockHash: m.BlockHash,
		Seeds:     m.stringSeeds(),
		Count:     uint8(len(m.Seeds)),
		Caller:    m.Caller,
		Type:      models.VRFRequestType_IMMEDIATE,
		Status:    models.VRFRequestStatus_ACTIVE,
	}
}

func (m *VRFChainJob) String() string {
	return fmt.Sprintf("\nVRFChainJob{ \n\tAssocID: %v, \n\tSeeds: %v, \n\tCreatedDate: %v\n}", m.AssocID, m.Seeds, m.CreatedDate)
}

func (m *VRFChainJob) stringSeeds() []string {
	ss := make([]string, 0, len(m.Seeds))
	for _, seed := range m.Seeds {
		ss = append(ss, string(seed))
	}
	return ss
}
