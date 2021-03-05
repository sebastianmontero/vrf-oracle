package contracts

import (
	eosc "github.com/eoscanada/eos-go"
	"github.com/sebastianmontero/vrf-oracle/core/services/eos"
)

type Contract struct {
	ContractName string
	EOS          *eos.EOS
}

func (m *Contract) SimpleTrx(action string, actor string, data interface{}) (*eosc.PushTransactionFullResp, error) {
	return m.EOS.SimpleTrx(
		m.ContractName,
		action,
		actor,
		data,
	)
}

func (m *Contract) DebugTrx(action string, actor string, data interface{}) (*eosc.PushTransactionFullResp, error) {
	return m.EOS.DebugTrx(
		m.ContractName,
		action,
		actor,
		data,
	)
}
