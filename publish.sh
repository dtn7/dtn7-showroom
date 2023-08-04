#!/bin/sh

docker buildx build --platform linux/amd64,linux/arm64 -t gh0st42/dtn7-showroom:v0.2.1 .

