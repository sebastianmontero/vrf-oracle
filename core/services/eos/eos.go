package eos

import (
	"context"
	"encoding/json"

	"github.com/eoscanada/eos-go"
	eosc "github.com/eoscanada/eos-go"
	"github.com/sebastianmontero/vrf-oracle/core/logger"
)

type EOS struct {
	API *eosc.API
}

func New(url string, pkeys []string) (*EOS, error) {
	api := eosc.New(url)
	api.SetSigner(&eosc.KeyBag{})
	eos := &EOS{
		API: api,
	}
	for _, pkey := range pkeys {
		err := eos.AddKey(pkey)
		if err != nil {
			return nil, err
		}
	}
	return eos, nil
}

func (m *EOS) AddKey(pkey string) error {
	// logger.Infof("PKey: %v", pkey)
	return m.API.Signer.ImportPrivateKey(context.Background(), pkey)
}

func (m *EOS) Trx(actions ...*eosc.Action) (*eosc.PushTransactionFullResp, error) {
	for _, action := range actions {
		logger.Infof("Trx Account: %v Name: %v, Authorization: %v, Data: %v", action.Account, action.Name, action.Authorization, action.ActionData)
		// js, _ := json.Marshal(action.ActionData)
		// logger.Infof("Data json: %v", string(js))
	}
	return m.API.SignPushActions(context.Background(), actions...)
}

func (m *EOS) SimpleTrx(contract, action, actor string, data interface{}) (*eosc.PushTransactionFullResp, error) {
	return m.Trx(buildAction(contract, action, actor, data))
}

func (m *EOS) DebugTrx(contract, action, actor string, data interface{}) (*eosc.PushTransactionFullResp, error) {
	txOpts := &eosc.TxOptions{}
	if err := txOpts.FillFromChain(context.Background(), m.API); err != nil {
		return nil, err
	}

	tx := eosc.NewTransaction([]*eosc.Action{buildAction(contract, action, actor, data)}, txOpts)
	signedTx, packedTx, err := m.API.SignTransaction(context.Background(), tx, txOpts.ChainID, eos.CompressionNone)
	if err != nil {
		return nil, err
	}

	content, err := json.MarshalIndent(signedTx, "", "  ")
	if err != nil {
		return nil, err
	}

	logger.Info(string(content))
	return m.API.PushTransaction(context.Background(), packedTx)
}

func buildAction(contract, action, actor string, data interface{}) *eosc.Action {
	return &eosc.Action{
		Account: eosc.AN(contract),
		Name:    eosc.ActN(action),
		Authorization: []eosc.PermissionLevel{
			{
				Actor:      eosc.AccountName(actor),
				Permission: eosc.PN("active"),
			},
		},
		ActionData: eosc.NewActionData(data),
	}
}
