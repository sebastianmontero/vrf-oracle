package dtos

import (
	"fmt"
	"strconv"

	"github.com/sebastianmontero/vrf-oracle/core/store/models"
)

type VRFChainJob struct {
	AssocID     uint64   `json:"assoc_id,omitempty"`
	Seeds       []uint64 `json:"seeds,omitempty"`
	CreatedDate string   `json:"created_date,omitempty"`
	BlockNum    uint64
	BlockHash   string
	Caller      string
}

func (m *VRFChainJob) VRFRequest() *models.VRFRequest {
	return &models.VRFRequest{
		AssocID:   m.AssocID,
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
		ss = append(ss, strconv.FormatUint(seed, 10))
	}
	return ss
}
