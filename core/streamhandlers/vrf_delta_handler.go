package streamhandlers

import (
	"encoding/json"

	"github.com/dfuse-io/bstream"
	pbcodec "github.com/dfuse-io/dfuse-eosio/pb/dfuse/eosio/codec/v1"
	pbbstream "github.com/dfuse-io/pbgo/dfuse/bstream/v1"
	"github.com/sebastianmontero/dfuse-firehose-client/dfclient"
	"github.com/sebastianmontero/vrf-oracle/core/logger"
	storepkg "github.com/sebastianmontero/vrf-oracle/core/store"
	"github.com/sebastianmontero/vrf-oracle/core/store/models"
	"github.com/sebastianmontero/vrf-oracle/core/streamhandlers/dtos"
)

type VRFDeltaHandler struct {
	Cursor   string
	JobTable string
	Store    *storepkg.Store
	Consumer chan *models.VRFRequest
}

func (m *VRFDeltaHandler) OnDelta(delta *dfclient.TableDelta, cursor string, forkStep pbbstream.ForkStep) {
	logger.Debugf("On Delta: \nCursor: %v \nFork Step: %v \nDelta %v ", cursor, forkStep, delta)
	if delta.TableName == m.JobTable {
		switch delta.Operation {
		case pbcodec.DBOp_OPERATION_INSERT:
			job := &dtos.VRFChainJob{}
			err := json.Unmarshal(delta.NewData, job)
			if err != nil {
				logger.Panicf("Error unmarshalling vrf job table new data: %v error: %v", string(delta.NewData), err)
			}
			job.Caller = delta.Scope
			job.BlockNum = uint64(delta.Block.Number)
			job.BlockHash = delta.Block.Id
			logger.Infof("VRFChainJob: ", job)
			request := job.VRFRequest()
			cr := &models.Cursor{
				ID:     models.CursorID_VRF_REQUESTS,
				Cursor: cursor,
			}
			logger.Infof("Storing: %v, v%", request, cr)
			err = m.Store.CreateVRFRequest(request, cr)
			if err != nil {
				logger.Panicf("Failed to store vrf request: %", request)
			}
			m.Consumer <- request
		case pbcodec.DBOp_OPERATION_UPDATE:
			logger.Panicf("VRF table updates should not be happening: %v", delta)
		case pbcodec.DBOp_OPERATION_REMOVE:
			logger.Tracef("Not handling vrf job removals: %v", string(delta.OldData))
		}
	}
	m.Cursor = cursor
}

func (m *VRFDeltaHandler) OnError(err error) {
	logger.Error(err, "On Error")
}

func (m *VRFDeltaHandler) OnComplete(lastBlockRef bstream.BlockRef) {
	logger.Infof("On Complete Last Block Ref: %v", lastBlockRef)
}
