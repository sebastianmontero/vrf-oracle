package contracts_test

import (
	"testing"

	eostest "github.com/digital-scarcity/eos-go-test"
	"github.com/sebastianmontero/vrf-oracle/core/services/eos"
	"github.com/sebastianmontero/vrf-oracle/core/services/eos/contracts"
	"github.com/sebastianmontero/vrf-oracle/core/services/vrf"
	"github.com/stretchr/testify/assert"
)

func TestSetRand(t *testing.T) {
	teardownTestCase := setupTestCase(t)
	defer teardownTestCase(t)
	env = SetupEnvironment(t)
	t.Log("\nEnvironment Setup complete\n")
	eos, err := eos.New(testingEndpoint, []string{eostest.DefaultKey()})
	assert.NoError(t, err)
	vrf := contracts.NewVRF(string(env.VRF), eos)
	assocID := uint64(1)
	seeds := []uint64{1}
	response, err := vrf.RequestRand(assocID, seeds, string(env.Caller))
	t.Log("Request Rand Response: ", response)
	assert.NoError(t, err)
	proofs := createProofs(assocID, seeds)
	response, err = vrf.SetRand(assocID, string(env.Caller), proofs)
	t.Log("Set Rand Response: ", response)
	assert.NoError(t, err)
}

func createProofs(assocID uint64, seeds []uint64) []*vrf.EOSProofResponse {
	proofs := make([]*vrf.EOSProofResponse, 0, len(seeds))
	for _, seed := range seeds {
		proofs = append(proofs, &vrf.EOSProofResponse{
			BlockNum:   1,
			BlockID:    "05c54b36d332142238ac94be8a854fb3a8a741ab2dde4e166c9f017b8068f5b0",
			Seed:       seed,
			FinalSeed:  "FinalSeed",
			PublicKey:  "PublicKey",
			Gamma:      "Gamma",
			C:          "C",
			S:          "S",
			OutputU256: "OutputU256",
			OutputU64:  3,
		})
	}
	return proofs
}
