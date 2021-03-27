package contracts

import (
	"fmt"

	eosc "github.com/eoscanada/eos-go"
	"github.com/sebastianmontero/vrf-oracle/core/services/eos"
	"github.com/sebastianmontero/vrf-oracle/core/services/vrf"
)

type VRF struct {
	*Contract
}

func NewVRF(contract string, eos *eos.EOS) *VRF {
	return &VRF{
		&Contract{
			ContractName: contract,
			EOS:          eos,
		},
	}
}

func (m *VRF) RequestRand(assocId uint64, seeds []uint64, caller string) (*eosc.PushTransactionFullResp, error) {
	return m.SimpleTrx(
		"requestrand",
		caller,
		&requestRand{
			AssocID: assocId,
			Caller:  eosc.AccountName(caller),
			Seeds:   seeds,
		},
	)
}

func (m *VRF) SetRand(assocId uint64, caller string, proofs []*vrf.EOSProofResponse) (*eosc.PushTransactionFullResp, error) {
	return m.SimpleTrx(
		"setrand",
		m.ContractName,
		&setRand{
			AssocID: assocId,
			Caller:  eosc.AccountName(caller),
			Proofs:  proofs,
		},
	)
}

type setRand struct {
	AssocID uint64                  `json:"assoc_id"`
	Caller  eosc.AccountName        `json:"caller"`
	Proofs  []*vrf.EOSProofResponse `json:"proofs"`
}

func (m *setRand) String() string {
	return fmt.Sprintf("\nsetRand{\n\tAssocID: %v, \n\tCaller %v, \n\tProofs: %v\n}", m.AssocID, m.Caller, m.Proofs)
}

type requestRand struct {
	AssocID uint64           `json:"assoc_id"`
	Seeds   []uint64         `json:"seeds"`
	Caller  eosc.AccountName `json:"caller"`
}

func (m *requestRand) String() string {
	return fmt.Sprintf("AssocID: %v, Seeds: %v, Caller %v", m.AssocID, m.Seeds, m.Caller)
}
