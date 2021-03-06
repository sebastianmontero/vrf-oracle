package web_test

import (
	"net/http"
	"testing"

	"github.com/sebastianmontero/vrf-oracle/core/services/eth"

	"github.com/sebastianmontero/vrf-oracle/core/internal/cltest"
	"github.com/sebastianmontero/vrf-oracle/core/store/presenters"
	"github.com/sebastianmontero/vrf-oracle/core/web"

	"github.com/manyminds/api2go/jsonapi"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestTxAttemptsController_Index_Success(t *testing.T) {
	t.Parallel()

	rpcClient, gethClient, _, assertMocksCalled := cltest.NewEthMocksWithStartupAssertions(t)
	defer assertMocksCalled()
	app, cleanup := cltest.NewApplicationWithKey(t,
		eth.NewClientWith(rpcClient, gethClient),
	)
	defer cleanup()

	require.NoError(t, app.Start())
	store := app.GetStore()
	client := app.NewHTTPClient()

	key := cltest.MustInsertRandomKey(t, store.DB, 0)
	from := key.Address.Address()

	cltest.MustInsertConfirmedEthTxWithAttempt(t, store, 0, 1, from)
	cltest.MustInsertConfirmedEthTxWithAttempt(t, store, 1, 2, from)
	cltest.MustInsertConfirmedEthTxWithAttempt(t, store, 2, 3, from)

	resp, cleanup := client.Get("/v2/tx_attempts?size=2")
	defer cleanup()
	cltest.AssertServerResponse(t, resp, http.StatusOK)

	var links jsonapi.Links
	var attempts []presenters.EthTx
	body := cltest.ParseResponseBody(t, resp)

	require.NoError(t, web.ParsePaginatedResponse(body, &attempts, &links))
	assert.NotEmpty(t, links["next"].Href)
	assert.Empty(t, links["prev"].Href)
	require.Len(t, attempts, 2)
	assert.Equal(t, "3", attempts[0].SentAt, "expected tx attempts order by sentAt descending")
	assert.Equal(t, "2", attempts[1].SentAt, "expected tx attempts order by sentAt descending")
}

func TestTxAttemptsController_Index_Error(t *testing.T) {
	t.Parallel()

	rpcClient, gethClient, _, assertMocksCalled := cltest.NewEthMocksWithStartupAssertions(t)
	defer assertMocksCalled()
	app, cleanup := cltest.NewApplicationWithKey(t,
		eth.NewClientWith(rpcClient, gethClient),
	)
	defer cleanup()

	require.NoError(t, app.Start())
	client := app.NewHTTPClient()
	resp, cleanup := client.Get("/v2/tx_attempts?size=TrainingDay")
	defer cleanup()
	cltest.AssertServerResponse(t, resp, 422)
}
