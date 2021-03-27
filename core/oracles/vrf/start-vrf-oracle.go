package main

import (
	pbbstream "github.com/dfuse-io/pbgo/dfuse/bstream/v1"

	"github.com/sebastianmontero/dfuse-firehose-client/dfclient"
	"github.com/sebastianmontero/vrf-oracle/core/gracefulpanic"
	"github.com/sebastianmontero/vrf-oracle/core/logger"
	"github.com/sebastianmontero/vrf-oracle/core/services/eos"
	"github.com/sebastianmontero/vrf-oracle/core/services/eos/contracts"
	"github.com/sebastianmontero/vrf-oracle/core/services/eth"
	"github.com/sebastianmontero/vrf-oracle/core/services/svrf"

	"github.com/sebastianmontero/vrf-oracle/core/services/postgres"
	strpkg "github.com/sebastianmontero/vrf-oracle/core/store"
	"github.com/sebastianmontero/vrf-oracle/core/store/models"
	"github.com/sebastianmontero/vrf-oracle/core/store/models/vrfkey"
	"github.com/sebastianmontero/vrf-oracle/core/store/orm"
	"github.com/sebastianmontero/vrf-oracle/core/streamhandlers"
)

func main() {
	config := orm.NewConfig()
	advisoryLocker := postgres.NewAdvisoryLock(config.DatabaseURL())
	shutdownSignal := gracefulpanic.NewSignal()
	store := strpkg.NewStore(config, &eth.NullClient{}, advisoryLocker, shutdownSignal, strpkg.StandardKeyStoreGen)
	config.SetRuntimeStore(store.ORM)
	store.Start()
	defer store.Close()

	key, err := getVRFKey(store, config)
	if err != nil {
		logger.Panic("Error getting vrf key: ", err)
	}

	client, err := dfclient.NewDfClient(config.FirehoseEndpoint(), config.DFuseAPIKey(), config.EOSURL(), nil)
	if err != nil {
		logger.Panic("Error creating dfclient: ", err)
	}

	cursor, err := store.FindCursor(models.CursorID_VRF_REQUESTS)
	if err != nil {
		logger.Panic("Error getting cursor: ", err)
	}
	eos, err := eos.New(config.EOSURL(), []string{config.VRFContractKey()})
	if err != nil {
		logger.Panic("Error creating eos instance: ", err)
	}
	vrfContract := contracts.NewVRF(config.VRFContract(), eos)
	vrfRequestChannel := make(chan *models.VRFRequest, 20)
	vrfResolver := svrf.NewVRFResolver(store, vrfContract, &key)
	go vrfResolver.Consume(vrfRequestChannel)
	logger.Infof("Cursor: %v", cursor)
	deltaRequest := &dfclient.DeltaStreamRequest{
		StartBlockNum:      config.VRFStartBlockNum(),
		StartCursor:        cursor.Cursor,
		StopBlockNum:       0,
		ForkSteps:          []pbbstream.ForkStep{pbbstream.ForkStep_STEP_NEW},
		ReverseUndoOps:     true,
		HeartBeatFrequency: uint(config.VRFHeartBeatFrequency()),
	}
	logger.Infof("Contract: %v, Table: %v, Loglevel: %v", config.VRFContract(), config.VRFJobTable(), config.LogLevel())
	// deltaRequest.AddTables("eosio.token", []string{"balance"})
	deltaRequest.AddTables(config.VRFContract(), []string{config.VRFJobTable()})
	client.DeltaStream(deltaRequest, &streamhandlers.VRFDeltaHandler{
		JobTable: config.VRFJobTable(),
		Store:    store,
		Consumer: vrfRequestChannel,
	})
}

func getVRFKey(store *strpkg.Store, config *orm.Config) (vrfkey.PublicKey, error) {

	keyStore := store.VRFKeyStore
	keys, err := keyStore.Unlock(config.VRFKeyStorePassword())
	if err != nil {
		return vrfkey.PublicKey{}, err
	}
	if len(keys) > 0 {
		return keys[0], err
	}
	logger.Info("There are no VRF keys, creating one")
	return store.VRFKeyStore.CreateKey(config.VRFKeyStorePassword())
}
