package web

import (
	"fmt"
	"net/http"

	"github.com/sebastianmontero/vrf-oracle/core/services/bulletprooftxmanager"
	"github.com/sebastianmontero/vrf-oracle/core/services/chainlink"
	"github.com/sebastianmontero/vrf-oracle/core/store/models"

	"github.com/gin-gonic/gin"
)

// TransfersController can send LINK tokens to another address
type TransfersController struct {
	App chainlink.Application
}

// Create sends ETH from the Chainlink's account to a specified address.
//
// Example: "<application>/withdrawals"
func (tc *TransfersController) Create(c *gin.Context) {
	var tr models.SendEtherRequest
	if err := c.ShouldBindJSON(&tr); err != nil {
		jsonAPIError(c, http.StatusBadRequest, err)
		return
	}

	store := tc.App.GetStore()

	etx, err := bulletprooftxmanager.SendEther(store, tr.FromAddress, tr.DestinationAddress, tr.Amount)
	if err != nil {
		jsonAPIError(c, http.StatusBadRequest, fmt.Errorf("transaction failed: %v", err))
		return
	}

	jsonAPIResponse(c, etx, "eth_tx")
}
