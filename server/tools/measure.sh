#!/bin/bash

CWD=$(cd $(dirname $0) && pwd)
TS=$(date +%s)
RET=$(grpcurl -plaintext -d "{\"start_ts\": $TS}" \
    -proto $2 \
    $1 latency_research_grpc.Service/Measure | jq .startTs)

if [ $RET -eq $TS ]; then
    echo "ok"
else
    exit 1
fi