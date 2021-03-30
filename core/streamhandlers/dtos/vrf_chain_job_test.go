package dtos_test

import (
	"encoding/json"
	"testing"

	"github.com/sebastianmontero/vrf-oracle/core/streamhandlers/dtos"
	"github.com/stretchr/testify/assert"
)

func TestDTO_UnmarshallVRFChainJob(t *testing.T) {
	//uint64 as string
	payload := `{
		"assoc_id":"1917081008500032",
		"created_date":"2021-03-30T05:10:08.5",
		"seeds":["1617081008500000"]
	}`

	job := &dtos.VRFChainJob{}
	err := json.Unmarshal([]byte(payload), job)
	assert.NoError(t, err)
	assert.Equal(t, uint64(1917081008500032), uint64(job.AssocID))
	assert.Equal(t, "2021-03-30T05:10:08.5", job.CreatedDate)
	assert.Len(t, job.Seeds, 1)
	assert.Equal(t, string(job.Seeds[0]), "1617081008500000")

	//unit64 as uint64
	payload = `{
		"assoc_id":10,
		"created_date":"2021-03-30T05:10:08.5",
		"seeds":[1617081008500000]
	}`

	job = &dtos.VRFChainJob{}
	err = json.Unmarshal([]byte(payload), job)
	assert.NoError(t, err)
	assert.Equal(t, uint64(10), uint64(job.AssocID))
	assert.Equal(t, "2021-03-30T05:10:08.5", job.CreatedDate)
	assert.Len(t, job.Seeds, 1)
	assert.Equal(t, string(job.Seeds[0]), "1617081008500000")

}
