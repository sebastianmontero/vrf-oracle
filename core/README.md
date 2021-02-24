<br/>
<p align="center">
<a href="https://chain.link" target="_blank">
<img src="https://raw.githubusercontent.com/smartcontractkit/explorer/develop/styleguide/static/images/logo-core-blue.svg" width="225" alt="Chainlink logo">
</a>
</p>
<br/>

[![Go Report Card](https://goreportcard.com/badge/github.com/smartcontractkit/chainlink)](https://goreportcard.com/report/github.com/smartcontractkit/chainlink)
[![GoDoc](https://godoc.org/github.com/smartcontractkit/chainlink?status.svg)](https://godoc.org/github.com/smartcontractkit/chainlink)

Chainlink Core is the API backend that Chainlink client contracts on Ethereum 
make requests to. The backend utulizes Solidity contract ABIs to generate types 
for interacting with Ethereum contracts.

## Features

* Headless API implementation
* CLI tool providing conveniance commands for node configuration, administration,
  and CRUD object operations (e.g. Jobs, Runs, and even the VRF)

## Installation

See the [root README](../README.md#install)
for instructions on how to build the full Chainlink node.

## Directory Structure

This directory contains the majority of the code for the backend of Chainlink.

Outside of the code contained in this repo, some static assets are pulled in using
[packr](https://github.com/gobuffalo/packr), in the sibling directory `packr/`.
 Additionally, the static assets generated by compiling the
sibling directory `operator-ui/` are built by packr and included in the final
binary.

## Common Commands

**Install:**

By default `go install` will install this directory under the name `core`.
You can instead, build it, and place it in your path as `chainlink`:

```
go build -o $GOPATH/bin/chainlink .
```

**Test:**

```
# A higher parallel number can speed up tests at the expense of more RAM.
go test -p 1 ./...
```

The golang testsuite is almost entirely parallelizable, and so running the default
`go test ./...` will commonly peg your processor. Limit parallelization with the
`-p 2` or whatever best fits your computer: `go test -p 4 ./...`.