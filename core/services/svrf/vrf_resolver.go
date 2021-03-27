package svrf

import (
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	"github.com/sebastianmontero/vrf-oracle/core/logger"
	"github.com/sebastianmontero/vrf-oracle/core/services/eos/contracts"
	"github.com/sebastianmontero/vrf-oracle/core/services/vrf"
	strpkg "github.com/sebastianmontero/vrf-oracle/core/store"
	"github.com/sebastianmontero/vrf-oracle/core/store/models"
	"github.com/sebastianmontero/vrf-oracle/core/store/models/vrfkey"
)

type VRFResolver struct {
	Store       *strpkg.Store
	VRFKeyStore *strpkg.VRFKeyStore
	VRFContract *contracts.VRF
	publicKey   *vrfkey.PublicKey
}

func NewVRFResolver(store *strpkg.Store, vrfContract *contracts.VRF, publicKey *vrfkey.PublicKey) *VRFResolver {
	return &VRFResolver{
		Store:       store,
		VRFKeyStore: store.VRFKeyStore,
		VRFContract: vrfContract,
		publicKey:   publicKey,
	}
}

func (m *VRFResolver) Consume(c chan *models.VRFRequest) {
	for req := range c {
		job := models.NewVRFRequestJob(req)
		m.saveJob(job)
		m.Process(job)
	}
}

func (m *VRFResolver) Process(job *models.VRFRequestJob) (*models.VRFRequestRun, error) {
	req := job.VRFRequest
	run := models.NewVRFRequestRun(job)
	m.saveRun(run, false)
	proofs := make([]*vrf.EOSProofResponse, 0, len(req.Seeds))
	for _, seed := range req.Seeds {
		bigSeed, ok := big.NewInt(0).SetString(seed, 10)
		if !ok {
			err := fmt.Errorf("Failed to parse seed: %v as big int", seed)
			m.failRun(run, err, 0) //Should fail immediately
			return run, err
		}

		preSeed, err := vrf.BigToSeed(bigSeed)
		if err != nil {
			err := fmt.Errorf("BigToSeed Failed: %v", err)
			m.failRun(run, err, 0)
			return run, err
		}
		proof, err := m.VRFKeyStore.GenerateEOSProof(*m.publicKey, vrf.PreSeedData{
			PreSeed:   preSeed,
			BlockHash: common.HexToHash(req.BlockHash),
			BlockNum:  req.BlockNum,
		})
		if err != nil {
			err := fmt.Errorf("GenerateEOSProof Failed: %v", err)
			m.failRun(run, err, m.maxRetries())
			return run, err
		}
		proofs = append(proofs, proof)
	}
	// logger.Infof("Calling SetRand for request: %v and proofs: %v", req, proofs)
	_, err := m.VRFContract.SetRand(req.AssocID, req.Caller, proofs)
	if err != nil {
		err := fmt.Errorf("Calling SetRand on contract failed: %v", err)
		m.failRun(run, err, m.maxRetries())
		return run, err
	}
	run.UpdateStatus(
		models.VRFRequestRunStatus_COMPLETED,
		"Completed successfully",
		m.maxRetries())
	m.saveRun(run, true)
	return run, nil
}

func (m *VRFResolver) maxRetries() uint8 {
	return m.Store.Config.VRFMaxRetries()
}

func (m *VRFResolver) saveRun(run *models.VRFRequestRun, saveVRFRequest bool) {
	err := m.Store.SaveVRFRequestRun(run, saveVRFRequest)
	if err != nil {
		logger.Panicf("Error storing vrf request run: %v", err)
	}
}

func (m *VRFResolver) saveJob(job *models.VRFRequestJob) {
	err := m.Store.SaveVRFRequestJob(job)
	if err != nil {
		logger.Panicf("Error storing vrf request run: %v", err)
	}
}

func (m *VRFResolver) failRun(run *models.VRFRequestRun, err error, maxRetries uint8) {
	logger.Error(err)

	run.UpdateStatus(
		models.VRFRequestRunStatus_FAILED,
		err.Error(),
		maxRetries)
	m.saveRun(run, true)
}
