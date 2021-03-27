package orm_test

import (
	"testing"
	"time"

	"github.com/lib/pq"
	"github.com/sebastianmontero/vrf-oracle/core/internal/cltest"
	"github.com/sebastianmontero/vrf-oracle/core/store/models"
	"github.com/sebastianmontero/vrf-oracle/core/store/orm"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gopkg.in/guregu/null.v4"
)

func TestORM_CreateVRFRequest(t *testing.T) {
	t.Parallel()
	store, cleanup := cltest.NewStore(t)
	defer cleanup()

	req1 := &models.VRFRequest{
		AssocID:   1,
		BlockNum:  395235,
		BlockHash: "000607e21b8d9da0ade735bcd19a9f8812335b510482d4b9f8c53753e0ebe9c8",
		Seeds:     pq.StringArray([]string{"2", "3"}),
		Frequency: "* * * * *",
		Count:     1,
		Caller:    "user1",
		Type:      models.VRFRequestType_RECURRENT,
		Status:    models.VRFRequestStatus_ACTIVE,
		StartAt:   null.TimeFrom(time.Now()),
		EndAt:     null.TimeFrom(time.Now().Add(time.Duration(1000 * 60 * 60 * 24 * 5))),
		CronID:    3,
	}
	err := store.CreateVRFRequest(req1, nil)
	require.NoError(t, err)

	req2, err := store.FindVRFRequest(req1.ID)
	require.NoError(t, err)
	// t.Logf("CreatedAt: %v UpdatedAt: %v", req1.CreatedAt, req1.UpdatedAt)
	// t.Logf("CreatedAt: %v UpdatedAt: %v", req2.CreatedAt, req2.UpdatedAt)
	assert.NotNil(t, req2.CreatedAt)
	assert.NotNil(t, req2.UpdatedAt)
	assert.False(t, req2.DeletedAt.Valid)
	validateVRFRequest(req2, req1, t)
}

func TestORM_FindCursor(t *testing.T) {
	t.Parallel()
	store, cleanup := cltest.NewStore(t)
	defer cleanup()

	cursor, err := store.FindCursor("non existant id")
	require.NoError(t, err)
	validateCursor(cursor, &models.Cursor{
		ID:     "",
		Cursor: "",
	}, t)
}

func TestORM_CreateVRFRequestWithCursor(t *testing.T) {
	t.Parallel()
	store, cleanup := cltest.NewStore(t)
	defer cleanup()

	req1 := &models.VRFRequest{
		AssocID:   1,
		BlockNum:  395235,
		BlockHash: "000607e21b8d9da0ade735bcd19a9f8812335b510482d4b9f8c53753e0ebe9c8",
		Seeds:     pq.StringArray([]string{"2", "3"}),
		Frequency: "* * * * 1",
		Count:     1,
		Caller:    "user2",
		Type:      models.VRFRequestType_RECURRENT,
		Status:    models.VRFRequestStatus_ACTIVE,
		StartAt:   null.TimeFrom(time.Now()),
		EndAt:     null.TimeFrom(time.Now().Add(time.Duration(1000 * 60 * 60 * 24 * 5))),
		CronID:    3,
	}
	cursor1 := &models.Cursor{
		ID:     models.CursorID_VRF_REQUESTS,
		Cursor: "c1",
	}
	err := store.CreateVRFRequest(req1, cursor1)
	require.NoError(t, err)

	req2, err := store.FindVRFRequest(req1.ID)
	require.NoError(t, err)
	validateVRFRequest(req2, req1, t)

	cursor2, err := store.FindCursor(models.CursorID_VRF_REQUESTS)
	require.NoError(t, err)
	validateCursor(cursor2, cursor1, t)
}

func TestORM_SaveVRFRequest(t *testing.T) {
	t.Parallel()
	store, cleanup := cltest.NewStore(t)
	defer cleanup()

	req1 := &models.VRFRequest{
		AssocID:   1,
		BlockNum:  395235,
		BlockHash: "000607e21b8d9da0ade735bcd19a9f8812335b510482d4b9f8c53753e0ebe9c8",
		Seeds:     pq.StringArray([]string{"2", "3"}),
		Frequency: "* * * * *",
		Count:     1,
		Caller:    "user1",
		Type:      models.VRFRequestType_RECURRENT,
		Status:    models.VRFRequestStatus_ACTIVE,
		StartAt:   null.TimeFrom(time.Now()),
		EndAt:     null.TimeFrom(time.Now().Add(time.Duration(1000 * 60 * 60 * 24 * 5))),
		CronID:    3,
	}
	err := store.CreateVRFRequest(req1, nil)
	require.NoError(t, err)

	req2, err := store.FindVRFRequest(req1.ID)
	require.NoError(t, err)
	assert.False(t, req2.DeletedAt.Valid)
	validateVRFRequest(req2, req1, t)

	updatedAt := req2.UpdatedAt
	req1.Seeds = pq.StringArray([]string{"2"})
	req1.Frequency = "1 * * * *"
	req1.Count = 2
	req1.Caller = "user2"
	req1.CronID = 7
	req1.Status = models.VRFRequestStatus_COMPLETED
	err = store.SaveVRFRequest(req1, nil)
	require.NoError(t, err)

	req2, err = store.FindVRFRequest(req1.ID)
	require.NoError(t, err)
	// t.Logf("CreatedAt: %v UpdatedAt: %v", req1.CreatedAt, req1.UpdatedAt)
	// t.Logf("CreatedAt: %v UpdatedAt: %v", req2.CreatedAt, req2.UpdatedAt)
	assert.True(t, updatedAt.Before(req2.UpdatedAt))
	assert.False(t, req2.DeletedAt.Valid)
	validateVRFRequest(req2, req1, t)
}

func TestORM_SaveVRFRequestWithCursor(t *testing.T) {
	t.Parallel()
	store, cleanup := cltest.NewStore(t)
	defer cleanup()

	req1 := &models.VRFRequest{
		AssocID:   1,
		BlockNum:  395235,
		BlockHash: "000607e21b8d9da0ade735bcd19a9f8812335b510482d4b9f8c53753e0ebe9c8",
		Seeds:     pq.StringArray([]string{"2", "3"}),
		Frequency: "* * * * *",
		Count:     1,
		Caller:    "user1",
		Type:      models.VRFRequestType_RECURRENT,
		Status:    models.VRFRequestStatus_ACTIVE,
		StartAt:   null.TimeFrom(time.Now()),
		EndAt:     null.TimeFrom(time.Now().Add(time.Duration(1000 * 60 * 60 * 24 * 5))),
		CronID:    3,
	}

	cursor1 := &models.Cursor{
		ID:     models.CursorID_VRF_REQUESTS,
		Cursor: "c1",
	}

	err := store.CreateVRFRequest(req1, cursor1)
	require.NoError(t, err)

	req2, err := store.FindVRFRequest(req1.ID)
	require.NoError(t, err)
	validateVRFRequest(req2, req1, t)

	cursor2, err := store.FindCursor(models.CursorID_VRF_REQUESTS)
	require.NoError(t, err)
	validateCursor(cursor2, cursor1, t)

	cursor1.Cursor = "c2"

	req1.Seeds = pq.StringArray([]string{"3"})
	req1.Frequency = "1 * * * *"
	req1.Count = 2
	req1.Caller = "user2"
	req1.CronID = 7
	req1.Status = models.VRFRequestStatus_COMPLETED
	err = store.SaveVRFRequest(req1, cursor1)
	require.NoError(t, err)

	req2, err = store.FindVRFRequest(req1.ID)
	require.NoError(t, err)
	validateVRFRequest(req2, req1, t)

	cursor2, err = store.FindCursor(models.CursorID_VRF_REQUESTS)
	require.NoError(t, err)
	validateCursor(cursor2, cursor1, t)
}

func TestORM_SaveVRFRequestOptimisticLocking(t *testing.T) {
	t.Parallel()
	store, cleanup := cltest.NewStore(t)
	defer cleanup()

	req1 := &models.VRFRequest{
		AssocID:   1,
		BlockNum:  395235,
		BlockHash: "000607e21b8d9da0ade735bcd19a9f8812335b510482d4b9f8c53753e0ebe9c8",
		Seeds:     pq.StringArray([]string{"2", "3"}),
		Frequency: "* * * * *",
		Count:     1,
		Caller:    "user1",
		Type:      models.VRFRequestType_RECURRENT,
		Status:    models.VRFRequestStatus_ACTIVE,
		StartAt:   null.TimeFrom(time.Now()),
		EndAt:     null.TimeFrom(time.Now().Add(time.Duration(1000 * 60 * 60 * 24 * 5))),
		CronID:    3,
	}
	err := store.CreateVRFRequest(req1, nil)
	require.NoError(t, err)

	req1.UpdatedAt = time.Now()
	err = store.SaveVRFRequest(req1, nil)
	require.Error(t, err)
	require.IsType(t, orm.ErrOptimisticUpdateConflict, err)
}

func TestORM_SaveCursor(t *testing.T) {
	t.Parallel()
	store, cleanup := cltest.NewStore(t)
	defer cleanup()

	cursor1 := &models.Cursor{
		ID:     models.CursorID_VRF_REQUESTS,
		Cursor: "c5",
	}

	err := store.SaveCursor(cursor1)
	require.NoError(t, err)

	cursor2, err := store.FindCursor(models.CursorID_VRF_REQUESTS)
	require.NoError(t, err)
	validateCursor(cursor2, cursor1, t)

	cursor1.Cursor = "c7"

	err = store.SaveCursor(cursor1)
	require.NoError(t, err)

	cursor2, err = store.FindCursor(models.CursorID_VRF_REQUESTS)
	require.NoError(t, err)
	validateCursor(cursor2, cursor1, t)
}

func TestORM_SaveVRFRequestJob(t *testing.T) {
	t.Parallel()
	store, cleanup := cltest.NewStore(t)
	defer cleanup()

	req1 := &models.VRFRequest{
		AssocID:   1,
		BlockNum:  395235,
		BlockHash: "000607e21b8d9da0ade735bcd19a9f8812335b510482d4b9f8c53753e0ebe9c8",
		Seeds:     pq.StringArray([]string{"2", "3"}),
		Frequency: "* * * * *",
		Count:     1,
		Caller:    "user1",
		Type:      models.VRFRequestType_RECURRENT,
		Status:    models.VRFRequestStatus_ACTIVE,
		StartAt:   null.TimeFrom(time.Now()),
		EndAt:     null.TimeFrom(time.Now().Add(time.Duration(1000 * 60 * 60 * 24 * 5))),
		CronID:    3,
	}
	err := store.CreateVRFRequest(req1, nil)
	require.NoError(t, err)

	job1 := &models.VRFRequestJob{
		VRFRequestID: req1.ID,
		VRFRequest:   req1,
		StartAt:      time.Now(),
		EndAt:        null.Time{},
		Status:       models.VRFRequestJobStatus_RUNNING,
		Retries:      0,
	}
	err = store.SaveVRFRequestJob(job1)
	require.NoError(t, err)

	job2, err := store.FindVRFRequestJob(job1.ID)
	require.NoError(t, err)
	validateVRFRequestJob(job2, job1, t)
}

func TestORM_SaveVRFRequestRun(t *testing.T) {
	t.Parallel()
	store, cleanup := cltest.NewStore(t)
	defer cleanup()

	seed := "5"
	req1 := &models.VRFRequest{
		AssocID:   3,
		Seeds:     pq.StringArray([]string{seed}),
		Frequency: "1 * * * *",
		Count:     2,
		Caller:    "user3",
		Type:      models.VRFRequestType_RECURRENT,
		Status:    models.VRFRequestStatus_ACTIVE,
		StartAt:   null.TimeFrom(time.Now()),
		EndAt:     null.TimeFrom(time.Now().Add(time.Duration(1000 * 60 * 60 * 24 * 5))),
		CronID:    4,
	}
	err := store.CreateVRFRequest(req1, nil)
	require.NoError(t, err)

	job1 := &models.VRFRequestJob{
		VRFRequestID: req1.ID,
		VRFRequest:   req1,
		StartAt:      time.Now(),
		EndAt:        null.Time{},
		Status:       models.VRFRequestJobStatus_RUNNING,
		Retries:      0,
	}
	err = store.SaveVRFRequestJob(job1)
	require.NoError(t, err)

	run1 := &models.VRFRequestRun{
		VRFRequestJobID: job1.ID,
		VRFRequestJob:   job1,
		StartAt:         time.Now(),
		EndAt:           null.TimeFrom(time.Now().Add(time.Duration(1000 * 60 * 60 * 24 * 5))),
		Status:          models.VRFRequestRunStatus_COMPLETED,
		StatusMsg:       "Success",
	}

	req1.Seeds = pq.StringArray([]string{"2"})
	job1.Status = models.VRFRequestJobStatus_ACTIVE

	err = store.SaveVRFRequestRun(run1, false)
	require.NoError(t, err)

	run2, err := store.FindVRFRequestRun(run1.ID)
	require.NoError(t, err)
	validateVRFRequestRun(run2, run1, t)

	job2, err := store.FindVRFRequestJob(job1.ID)
	require.NoError(t, err)
	validateVRFRequestJob(job2, job1, t)

	req2, err := store.FindVRFRequest(req1.ID)
	require.NoError(t, err)
	assert.Equalf(t, seed, req2.Seeds[0], "Seed must match old value")

	run1.Status = models.VRFRequestRunStatus_FAILED
	run1.StatusMsg = "Error"
	job1.Status = models.VRFRequestJobStatus_FAILED

	err = store.SaveVRFRequestRun(run1, true)
	require.NoError(t, err)

	run2, err = store.FindVRFRequestRun(run1.ID)
	require.NoError(t, err)
	validateVRFRequestRun(run2, run1, t)

	job2, err = store.FindVRFRequestJob(job1.ID)
	require.NoError(t, err)
	validateVRFRequestJob(job2, job1, t)

	req2, err = store.FindVRFRequest(req1.ID)
	require.NoError(t, err)
	validateVRFRequest(req2, req1, t)
}

func validateVRFRequest(actual *models.VRFRequest, expected *models.VRFRequest, t *testing.T) {
	assert.Equal(t, actual.ID, expected.ID)
	assert.Equal(t, actual.AssocID, expected.AssocID)
	assert.Equal(t, actual.BlockNum, expected.BlockNum)
	assert.Equal(t, actual.BlockHash, expected.BlockHash)
	assert.Equal(t, actual.Seeds, expected.Seeds)
	assert.Equal(t, actual.Frequency, expected.Frequency)
	assert.Equal(t, actual.Count, expected.Count)
	assert.Equal(t, actual.Caller, expected.Caller)
	assert.Equal(t, actual.Type, expected.Type)
	assert.Equal(t, actual.Status, expected.Status)
	// t.Logf("Expected: %v Actual: %v", actual.StartAt, expected.StartAt)
	// assert.True(t, actual.StartAt.Equal(expected.StartAt))
	// t.Logf("Expected: %v Actual: %v", actual.EndAt, expected.EndAt)
	// assert.True(t, actual.EndAt.Equal(expected.EndAt))
	assert.Equal(t, actual.CronID, expected.CronID)
}

func validateVRFRequestJob(actual *models.VRFRequestJob, expected *models.VRFRequestJob, t *testing.T) {
	assert.Equal(t, actual.ID, expected.ID)
	assert.Equal(t, actual.VRFRequestID, expected.VRFRequestID)
	assert.Equal(t, actual.Status, expected.Status)
	assert.Equal(t, actual.Retries, expected.Retries)
	// validateVRFRequest(actual.VRFRequest, expected.VRFRequest, t)
}

func validateVRFRequestRun(actual *models.VRFRequestRun, expected *models.VRFRequestRun, t *testing.T) {
	assert.Equal(t, actual.ID, expected.ID)
	assert.Equal(t, actual.VRFRequestJobID, expected.VRFRequestJobID)
	assert.Equal(t, actual.Status, expected.Status)
	assert.Equal(t, actual.StatusMsg, expected.StatusMsg)
	// validateVRFRequest(actual.VRFRequest, expected.VRFRequest, t)
}

func validateCursor(actual *models.Cursor, expected *models.Cursor, t *testing.T) {
	assert.Equal(t, actual.ID, expected.ID)
	assert.Equal(t, actual.Cursor, expected.Cursor)
}
