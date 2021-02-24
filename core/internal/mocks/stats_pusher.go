// Code generated by mockery v2.5.1. DO NOT EDIT.

package mocks

import (
	synchronization "github.com/sebastianmontero/vrf-oracle/core/services/synchronization"
	models "github.com/sebastianmontero/vrf-oracle/core/store/models"
	mock "github.com/stretchr/testify/mock"

	url "net/url"
)

// StatsPusher is an autogenerated mock type for the StatsPusher type
type StatsPusher struct {
	mock.Mock
}

// AllSyncEvents provides a mock function with given fields: cb
func (_m *StatsPusher) AllSyncEvents(cb func(models.SyncEvent) error) error {
	ret := _m.Called(cb)

	var r0 error
	if rf, ok := ret.Get(0).(func(func(models.SyncEvent) error) error); ok {
		r0 = rf(cb)
	} else {
		r0 = ret.Error(0)
	}

	return r0
}

// Close provides a mock function with given fields:
func (_m *StatsPusher) Close() error {
	ret := _m.Called()

	var r0 error
	if rf, ok := ret.Get(0).(func() error); ok {
		r0 = rf()
	} else {
		r0 = ret.Error(0)
	}

	return r0
}

// GetStatus provides a mock function with given fields:
func (_m *StatsPusher) GetStatus() synchronization.ConnectionStatus {
	ret := _m.Called()

	var r0 synchronization.ConnectionStatus
	if rf, ok := ret.Get(0).(func() synchronization.ConnectionStatus); ok {
		r0 = rf()
	} else {
		r0 = ret.Get(0).(synchronization.ConnectionStatus)
	}

	return r0
}

// GetURL provides a mock function with given fields:
func (_m *StatsPusher) GetURL() url.URL {
	ret := _m.Called()

	var r0 url.URL
	if rf, ok := ret.Get(0).(func() url.URL); ok {
		r0 = rf()
	} else {
		r0 = ret.Get(0).(url.URL)
	}

	return r0
}

// PushNow provides a mock function with given fields:
func (_m *StatsPusher) PushNow() {
	_m.Called()
}

// Start provides a mock function with given fields:
func (_m *StatsPusher) Start() error {
	ret := _m.Called()

	var r0 error
	if rf, ok := ret.Get(0).(func() error); ok {
		r0 = rf()
	} else {
		r0 = ret.Error(0)
	}

	return r0
}
