package orm

import (
	"github.com/jinzhu/gorm"
	"github.com/sebastianmontero/vrf-oracle/core/store/models"
)

// CreateVRFRequest inserts a new VRFRequest
func (orm *ORM) CreateVRFRequest(req *models.VRFRequest) error {
	if err := orm.MustEnsureAdvisoryLock(); err != nil {
		return err
	}
	return orm.DB.Create(req).Error
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
func (orm *ORM) SaveVRFRequest(req *models.VRFRequest) error {
	return orm.convenientTransaction(func(dbtx *gorm.DB) error {
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
	})
}
