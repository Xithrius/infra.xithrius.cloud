#!/bin/bash

function check_and_create_docker_network() {
    network=$1

    if docker network inspect ${network} &>/dev/null; then
        echo "Docker network ${network} already exists"
        return 1
    fi

    echo "Creating docker network: ${network}"
    docker network create ${network}
    return 0
}
