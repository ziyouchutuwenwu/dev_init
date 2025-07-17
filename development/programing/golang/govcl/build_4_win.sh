#!/bin/bash

GOOS=windows GOARCH=386 go build -tags tempdll -ldflags="-H windowsgui"