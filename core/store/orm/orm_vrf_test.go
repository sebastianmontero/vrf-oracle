package orm_test

import (
	"testing"
	"time"

	"github.com/sebastianmontero/vrf-oracle/core/internal/cltest"
	"github.com/sebastianmontero/vrf-oracle/core/store/models"
	"github.com/sebastianmontero/vrf-oracle/core/store/orm"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestORM_CreateVRFRequest(t *testing.T) {
	t.Parallel()
	store, cleanup := cltest.NewStore(t)
	defer cleanup()

	req1 := &models.VRFRequest{
		AssocID:     1,
		Seed:        2,
		Frequency:   "* * * * *",
		Count:       1,
		Caller:      "user1",
		StartAt:     time.Now(),
		EndAt:       time.Now().Add(time.Duration(1000 * 60 * 60 * 24 * 5)),
		StartCronID: 4,
		CronID:      3,
		EndCronID:   3,
	}
	err := store.CreateVRFRequest(req1)
	require.NoError(t, err)

	req2, err := store.FindVRFRequest(req1.ID)
	require.NoError(t, err)
	// t.Logf("CreatedAt: %v UpdatedAt: %v", req1.CreatedAt, req1.UpdatedAt)
	// t.Logf("CreatedAt: %v UpdatedAt: %v", req2.CreatedAt, req2.UpdatedAt)
	assert.NotNil(t, req2.CreatedAt)
	assert.NotNil(t, req2.UpdatedAt)
	assert.False(t, req2.DeletedAt.Valid)
	validateRequest(req2, req1, t)
}

func TestORM_SaveVRFRequest(t *testing.T) {
	t.Parallel()
	store, cleanup := cltest.NewStore(t)
	defer cleanup()

	req1 := &models.VRFRequest{
		AssocID:     1,
		Seed:        2,
		Frequency:   "* * * * *",
		Count:       1,
		Caller:      "user1",
		StartAt:     time.Now(),
		EndAt:       time.Now().Add(time.Duration(1000 * 60 * 60 * 24 * 5)),
		StartCronID: 4,
		CronID:      3,
		EndCronID:   3,
	}
	err := store.CreateVRFRequest(req1)
	require.NoError(t, err)

	req2, err := store.FindVRFRequest(req1.ID)
	require.NoError(t, err)
	assert.False(t, req2.DeletedAt.Valid)
	validateRequest(req2, req1, t)

	updatedAt := req2.UpdatedAt
	req1.Seed = 3
	req1.Frequency = "1 * * * *"
	req1.Count = 2
	req1.Caller = "user2"
	req1.StartCronID = 5
	req1.CronID = 7
	req1.EndCronID = 10
	err = store.SaveVRFRequest(req1)
	require.NoError(t, err)

	req2, err = store.FindVRFRequest(req1.ID)
	require.NoError(t, err)
	// t.Logf("CreatedAt: %v UpdatedAt: %v", req1.CreatedAt, req1.UpdatedAt)
	// t.Logf("CreatedAt: %v UpdatedAt: %v", req2.CreatedAt, req2.UpdatedAt)
	assert.True(t, updatedAt.Before(req2.UpdatedAt))
	assert.False(t, req2.DeletedAt.Valid)
	validateRequest(req2, req1, t)
}

func TestORM_SaveVRFRequestOptimisticLocking(t *testing.T) {
	t.Parallel()
	store, cleanup := cltest.NewStore(t)
	defer cleanup()

	req1 := &models.VRFRequest{
		AssocID:     1,
		Seed:        2,
		Frequency:   "* * * * *",
		Count:       1,
		Caller:      "user1",
		StartAt:     time.Now(),
		EndAt:       time.Now().Add(time.Duration(1000 * 60 * 60 * 24 * 5)),
		StartCronID: 4,
		CronID:      3,
		EndCronID:   3,
	}
	err := store.CreateVRFRequest(req1)
	require.NoError(t, err)

	req1.UpdatedAt = time.Now()
	err = store.SaveVRFRequest(req1)
	require.Error(t, err)
	require.IsType(t, orm.ErrOptimisticUpdateConflict, err)
}

func validateRequest(actual *models.VRFRequest, expected *models.VRFRequest, t *testing.T) {
	assert.Equal(t, actual.ID, expected.ID)
	assert.Equal(t, actual.AssocID, expected.AssocID)
	assert.Equal(t, actual.Seed, expected.Seed)
	assert.Equal(t, actual.Frequency, expected.Frequency)
	assert.Equal(t, actual.Count, expected.Count)
	assert.Equal(t, actual.Caller, expected.Caller)
	// t.Logf("Expected: %v Actual: %v", actual.StartAt, expected.StartAt)
	// assert.True(t, actual.StartAt.Equal(expected.StartAt))
	// t.Logf("Expected: %v Actual: %v", actual.EndAt, expected.EndAt)
	// assert.True(t, actual.EndAt.Equal(expected.EndAt))
	assert.Equal(t, actual.StartCronID, expected.StartCronID)
	assert.Equal(t, actual.EndCronID, expected.EndCronID)
	assert.Equal(t, actual.CronID, expected.CronID)
}
