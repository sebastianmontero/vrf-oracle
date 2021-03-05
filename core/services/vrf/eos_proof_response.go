package vrf

import (
	"bytes"
	"encoding/base64"
	"fmt"

	"go.dedis.ch/kyber/v3"
)

//EOSProofResponse Proof response sent to an eosio chain
type EOSProofResponse struct {
	BlockNum   uint64 `json:"block_num"`
	BlockID    string `json:"block_id"`
	Seed       uint64 `json:"seed"`
	FinalSeed  string `json:"final_seed"`
	PublicKey  string `json:"public_key"`
	Gamma      string `json:"gamma"`
	C          string `json:"c"`
	S          string `json:"s"`
	OutputU256 string `json:"output_u256"`
	OutputU64  uint64 `json:"output_u64"`
}

//NewEOSProofResponse Creates an EOSProofResponse from a ProofResponse
func NewEOSProofResponse(pr *ProofResponse) *EOSProofResponse {
	return &EOSProofResponse{
		BlockNum:   pr.BlockNum,
		BlockID:    pr.BlockHash.String(),
		Seed:       pr.PreSeed.Big().Uint64(),
		FinalSeed:  pr.P.Seed.Text(10),
		PublicKey:  encodeKyberPoint(&pr.P.PublicKey),
		Gamma:      encodeKyberPoint(&pr.P.Gamma),
		C:          pr.P.C.Text(10),
		S:          pr.P.S.Text(10),
		OutputU256: pr.P.Output.Text(10),
		OutputU64:  pr.P.OutputU64,
	}
}

func (m *EOSProofResponse) String() string {
	return fmt.Sprintf(
		"EOSProofResponse{ BlockNum: %v, BlockID: %v, Seed: %v, FinalSeed: %v, PublicKey: %v, Gamma: %v, C: %v, S: %v, OutputU256: %v, OutputU64: %v}",
		m.BlockNum,
		string(m.BlockID),
		m.Seed,
		m.FinalSeed,
		m.PublicKey,
		m.Gamma,
		m.C,
		m.S,
		m.OutputU256,
		m.OutputU64,
	)
}

func encodeKyberPoint(kp *kyber.Point) string {
	var buf bytes.Buffer
	(*kp).MarshalTo(&buf)
	return base64.StdEncoding.EncodeToString(buf.Bytes())
}
