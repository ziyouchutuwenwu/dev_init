#!/bin/bash

GOOS=windows GOARCH=386 go build -i -tags tempdll -ldflags="-H windowsgui"