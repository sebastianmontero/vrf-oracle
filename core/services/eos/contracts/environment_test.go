package contracts_test

import (
	"context"
	"testing"

	eostest "github.com/digital-scarcity/eos-go-test"

	eos "github.com/eoscanada/eos-go"
	"github.com/stretchr/testify/assert"
)

type Environment struct {
	ctx context.Context
	api eos.API

	VRF    eos.AccountName
	Caller eos.AccountName
}

func SetupEnvironment(t *testing.T) *Environment {

	var env Environment
	env.api = *eos.New(testingEndpoint)
	// api.Debug = true
	env.ctx = context.Background()

	keyBag := &eos.KeyBag{}
	err := keyBag.ImportPrivateKey(env.ctx, eostest.DefaultKey())
	assert.NoError(t, err)

	env.api.SetSigner(keyBag)

	env.VRF, err = eostest.CreateAccountFromString(env.ctx, &env.api, "vrf", eostest.DefaultKey())
	assert.NoError(t, err)

	_, err = eostest.SetContract(env.ctx, &env.api, env.VRF, "/home/sebastian/vsc-workspace/BennyFi/vrf/build/vrf/vrf.wasm", "/home/sebastian/vsc-workspace/BennyFi/vrf/build/vrf/vrf.abi")
	assert.NoError(t, err)

	env.Caller, err = eostest.CreateAccountFromString(env.ctx, &env.api, "caller", eostest.DefaultKey())
	assert.NoError(t, err)

	_, err = eostest.SetContract(env.ctx, &env.api, env.Caller, "/home/sebastian/vsc-workspace/BennyFi/vrf/build/vrf/callerstub.wasm", "/home/sebastian/vsc-workspace/BennyFi/vrf/build/vrf/callerstub.abi")
	assert.NoError(t, err)

	// for i := 1; i < 5; i++ {

	// 	creator, err := eostest.CreateAccountFromString(env.ctx, &env.api, "creator"+strconv.Itoa(i), eostest.DefaultKey())
	// 	assert.NoError(t, err)

	// 	env.Creators = append(env.Creators, creator)
	// }
	return &env
}
