package orm

import (
	"github.com/jinzhu/gorm"
	"github.com/sebastianmontero/vrf-oracle/core/store/models"
)

// CreateVRFRequest inserts a new VRFRequest
func (orm *ORM) CreateVRFRequest(req *models.VRFRequest, cursor *models.Cursor) error {
	return orm.convenientTransaction(func(dbtx *gorm.DB) error {
		err := orm.DB.Create(req).Error
		if err != nil {
			return err
		}
		return orm.SaveCursor(cursor, dbtx)
	})
}

// FindVRFRequest looks up a VRFRequest by its ID.
func (orm *ORM) FindVRFRequest(id uint64) (*models.VRFRequest, error) {
	req := &models.VRFRequest{}
	if err := orm.MustEnsureAdvisoryLock(); err != nil {
		return req, err
	}
	return req, orm.DB.First(req, id).Error
}

// SaveVRFRequest updates UpdatedAt for a VRFRequest and saves it
func (orm *ORM) SaveVRFRequest(req *models.VRFRequest, cursor *models.Cursor) error {
	return orm.convenientTransaction(func(dbtx *gorm.DB) error {
		err := orm.saveVRFRequest(req, cursor, dbtx)
		if err != nil {
			return err
		}
		return orm.SaveCursor(cursor, dbtx)
	})
}

// saveVRFRequest core of saveVRFRequest so that it can be reutilized updates UpdatedAt for a VRFRequest and saves it
func (orm *ORM) saveVRFRequest(req *models.VRFRequest, cursor *models.Cursor, dbtx *gorm.DB) error {
	result := dbtx.Unscoped().
		Model(req).
		Where("updated_at = ?", req.UpdatedAt).
		Omit("deleted_at").
		Save(req)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return ErrOptimisticUpdateConflict
	}
	return nil
}

// SaveCursor saves cursor
func (orm *ORM) SaveCursor(cursor *models.Cursor, dbtx *gorm.DB) error {
	return orm.convenientTransaction(func(dbtx *gorm.DB) error {
		if cursor != nil {
			return dbtx.Save(cursor).Error
		}
		return nil
	})
}

// FindCursor looks up a Cursor by its ID.
func (orm *ORM) FindCursor(id models.CursorID) (*models.Cursor, error) {
	cursor := &models.Cursor{}
	if err := orm.MustEnsureAdvisoryLock(); err != nil {
		return cursor, err
	}
	return cursor, orm.DB.First(cursor, "id = ?", id).Error
}

// SaveVRFRequestJob looks up a VRFRequestJob by its ID.
func (orm *ORM) SaveVRFRequestJob(job *models.VRFRequestJob) error {
	if err := orm.MustEnsureAdvisoryLock(); err != nil {
		return err
	}
	return orm.DB.Omit("VRFRequest").Save(job).Error
}

// FindVRFRequestJob looks up a VRFRequestJob by its ID.
func (orm *ORM) FindVRFRequestJob(id uint64) (*models.VRFRequestJob, error) {
	job := &models.VRFRequestJob{}
	if err := orm.MustEnsureAdvisoryLock(); err != nil {
		return job, err
	}
	return job, orm.DB.First(job, id).Error
}

// SaveVRFRequestRun looks up a VRFRequestRun by its ID.
func (orm *ORM) SaveVRFRequestRun(run *models.VRFRequestRun, saveVRFRequest bool) error {
	return orm.convenientTransaction(func(dbtx *gorm.DB) error {

		err := dbtx.Omit("VRFRequestJob").Save(run).Error
		if err != nil {
			return err
		}
		err = dbtx.Omit("VRFRequest").Save(run.VRFRequestJob).Error
		if err != nil {
			return err
		}
		if saveVRFRequest {
			err := orm.saveVRFRequest(run.VRFRequestJob.VRFRequest, nil, dbtx)
			if err != nil {
				return err
			}
		}
		return nil
	})
}

// FindVRFRequestRun looks up a VRFRequestRun by its ID.
func (orm *ORM) FindVRFRequestRun(id uint64) (*models.VRFRequestRun, error) {
	run := &models.VRFRequestRun{}
	if err := orm.MustEnsureAdvisoryLock(); err != nil {
		return run, err
	}
	return run, orm.DB.First(run, id).Error
}
