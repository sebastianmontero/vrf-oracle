package main

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	"github.com/sebastianmontero/vrf-oracle/core/gracefulpanic"
	"github.com/sebastianmontero/vrf-oracle/core/services/eth"
	"github.com/sebastianmontero/vrf-oracle/core/services/postgres"
	"github.com/sebastianmontero/vrf-oracle/core/services/vrf"
	strpkg "github.com/sebastianmontero/vrf-oracle/core/store"
	"github.com/sebastianmontero/vrf-oracle/core/store/orm"
)

func main() {
	config := orm.NewConfig()
	advisoryLocker := postgres.NewAdvisoryLock(config.DatabaseURL())
	shutdownSignal := gracefulpanic.NewSignal()
	store := strpkg.NewStore(config, &eth.NullClient{}, advisoryLocker, shutdownSignal, strpkg.StandardKeyStoreGen)
	config.SetRuntimeStore(store.ORM)
	store.Start()
	defer store.Close()
	// pk, err := store.VRFKeyStore.CreateKey("password")
	// if err != nil {
	// 	fmt.Print("Error: ", err)
	// }
	// fmt.Print("PK: ", pk)
	keyStore := store.VRFKeyStore
	keys, err := keyStore.Unlock("password")
	if err != nil {
		fmt.Println("Error: ", err)
		return
	}
	fmt.Println("Keys: ", keys)
	seed, err := vrf.BigToSeed(big.NewInt(149))
	if err != nil {
		fmt.Println("Error: ", err)
		return
	}
	proof, err := keyStore.GenerateUnmarshaledProof(keys[0], vrf.PreSeedData{
		PreSeed:   seed,
		BlockHash: common.BigToHash(big.NewInt(1000)),
		BlockNum:  100,
	})
	if err != nil {
		fmt.Println("Error: ", err)
		return
	}

	eosProof, err := keyStore.GenerateEOSProof(keys[0], vrf.PreSeedData{
		PreSeed:   seed,
		BlockHash: common.BigToHash(big.NewInt(1000)),
		BlockNum:  100,
	})
	if err != nil {
		fmt.Println("Error: ", err)
		return
	}

	fmt.Println("EOSProof Response: ", eosProof)
	// fmt.Println("Marshalled Proof: ", proof)
	// goProof, err := vrf.UnmarshalProofResponse(proof)
	fmt.Println("UnMarshalled Response: ", proof)
	randomValue := proof.P.Output
	max64 := ^uint64(0)
	maxUint64 := big.NewInt(0).SetUint64(max64)
	maxUint256 := big.NewInt(0).Sub(big.NewInt(0).Exp(big.NewInt(2), big.NewInt(256), nil), big.NewInt(1))
	randomValue.Mul(randomValue, maxUint64).Div(randomValue, maxUint256)
	rv := randomValue.Uint64()
	rvf := float64(rv)
	j, err := json.Marshal(proof)
	fmt.Println(string(j))
	var buf bytes.Buffer
	proof.P.PublicKey.MarshalTo(&buf)
	fmt.Println("Encoded public key: ", buf)
	fmt.Println("Encoded public key: ", base64.StdEncoding.EncodeToString(buf.Bytes()))
	var buf1 bytes.Buffer
	proof.P.Gamma.MarshalTo(&buf1)
	fmt.Println("Encoded gamma: ", buf1)
	fmt.Println("Encoded gamma: ", base64.StdEncoding.EncodeToString(buf1.Bytes()))

	fmt.Println("Kyber point: ", proof.P.PublicKey)
	fmt.Println("Max Value64: ", max64)
	fmt.Println("Max Value: ", maxUint64.Text(10))
	fmt.Println("Scaled Random value: ", randomValue.Text(10))
	fmt.Println("Scaled Random value: ", rv)
	fmt.Println("Scaled Random value: ", proof.P.OutputU64)
	fmt.Println("Scaled Random value 64: ", (rvf/float64(max64))*64)
	fmt.Println("Scaled Random value 64: ", int((rvf/float64(max64))*64))
	fmt.Println("Is uint64: ", randomValue.IsUint64())

	// randomValuef := big.NewFloat(0).SetInt(goProof.P.Output)
	// maxUint64f := big.NewFloat(0).SetInt(maxUint64)
	// maxUint256f := big.NewFloat(0).SetInt(big.NewInt(0).Sub(big.NewInt(0).Exp(big.NewInt(2), big.NewInt(256), nil), big.NewInt(1)))
	// randomValuef.Mul(randomValuef, maxUint64f).Quo(randomValuef, maxUint256f)
	// // rvfi := randomValue.Uint64()
	// randomValuefi, _ := randomValuef.Int(nil)
	// maxUint64fi, _ := maxUint64f.Int(nil)
	// // maxUint256fi, _ := maxUint256f.Int(nil)
	// rvfi := randomValuefi.Uint64()
	// fmt.Println("Max Value: ", maxUint64f.Text('f', 0))
	// fmt.Println("Max Value256: ", maxUint256f.Text('f', 0))
	// fmt.Println("Max Value: ", maxUint64fi.Text(10))
	// fmt.Println("Scaled Random value: ", randomValuef.Text('f', 0))
	// fmt.Println("Scaled Random value: ", randomValuefi.Text(10))
	// fmt.Println("Scaled Random value: ", rvfi)
	// fmt.Println("Scaled Random value 64: ", rvfi*64/maxUint64fi.Uint64())
	// fmt.Println("Is uint64: ", randomValuefi.IsUint64())

}
