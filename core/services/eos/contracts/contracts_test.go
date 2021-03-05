package contracts_test

import (
	"os"
	"os/exec"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

const testingEndpoint = "http://localhost:8888"

var env *Environment
var chainResponsePause time.Duration

func setupTestCase(t *testing.T) func(t *testing.T) {
	t.Log("Bootstrapping testing environment ...")

	_, err := exec.Command("sh", "-c", "pkill -SIGINT nodeos").Output()
	if err == nil {
		pause(t, time.Second, "Killing nodeos ...", "")
	}

	t.Log("Starting nodeos from 'nodeos.sh' script ...")
	cmd := exec.Command("./nodeos.sh")
	cmd.Stdout = os.Stdout
	err = cmd.Start()
	assert.NoError(t, err)
	chainResponsePause = time.Second

	t.Log("nodeos PID: ", cmd.Process.Pid)

	pause(t, 500*time.Millisecond, "", "")

	return func(t *testing.T) {
		//What to do when tearing down test case
	}
}
