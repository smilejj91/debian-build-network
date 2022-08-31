#!/bin/bash

docker run -t --hostname bulidd --name wanna-build -p 2222:22 harbor.tmaxos.net/infra/wanna-build:1.0.0
