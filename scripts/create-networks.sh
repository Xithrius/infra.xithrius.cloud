#!/bin/bash

. common.sh

networks=(
    "database-access"
    "infra-metrics"
    "api-metrics"
    "xythrion"
    "ordis"
)

echo "Creating docker networks..."

for network in "${networks[@]}"; do
    check_and_create_docker_network ${network}
done

echo "Done."
