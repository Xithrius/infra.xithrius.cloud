#!/bin/bash

check_network() {
    if ! docker network inspect $DOCKER_NETWORK &>/dev/null; then
        echo "Creating docker network: $DOCKER_NETWORK"
        docker network create $DOCKER_NETWORK
    fi
}

check_postgres_container() {
    if ! docker ps -f name="$POSTGRES_CONTAINER" --format '{{.Names}}' | grep -q "$POSTGRES_CONTAINER"; then
        echo "Starting postgres container: $POSTGRES_CONTAINER"
        docker-compose up -d postgres
    fi
}

check_database_existence() {
    local database=$1
    local username=$2

    local retries=5
    local wait_seconds=1

    for ((i = 1; i <= retries; i++)); do
        if docker exec $POSTGRES_CONTAINER psql -U $username -lqt &>/dev/null; then
            break
        else
            echo "PostgreSQL container not ready. Attempt $i of $retries..."
            sleep $wait_seconds
        fi
    done

    if ! docker exec $POSTGRES_CONTAINER psql -U $username -lqt | cut -d \| -f 1 | grep -qw $database; then
        echo "Creating database: $database"
        docker exec $POSTGRES_CONTAINER psql -U $username -c "CREATE DATABASE $database;"
    fi
}

create_user_and_grant_privileges() {
    local elevated_username=$1
    local database=$2
    local username=$3
    local password=$4

    # Check if the user exists
    if ! docker exec $POSTGRES_CONTAINER psql -U $elevated_username -tAc "SELECT 1 FROM pg_roles WHERE rolname='$username'" | grep -q 1; then
        echo "Creating user: $username"
        docker exec $POSTGRES_CONTAINER psql -U $elevated_username -c "CREATE USER $username WITH ENCRYPTED PASSWORD '$password';"
    fi

    # Grant privileges to the user
    echo "Granting privileges to user: $username"
    docker exec $POSTGRES_CONTAINER psql -U $elevated_username -d $database -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $username;"
    docker exec $POSTGRES_CONTAINER psql -U $elevated_username -d $database -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $username;"
    docker exec $POSTGRES_CONTAINER psql -U $elevated_username -d $database -c "GRANT CREATE ON SCHEMA public TO $username;"
    docker exec $POSTGRES_CONTAINER psql -U $elevated_username -d $database -c "GRANT CREATE ON DATABASE $database TO $username;"
    docker exec $POSTGRES_CONTAINER psql -U $elevated_username -d $database -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
}


if [ $# -ne 4 ]; then
    echo "Usage: $0 <database_name> <elevated_username> <username> <password>"
    exit 1
fi

ELEVATED_USERNAME=$1
DATABASE_NAME=$2
USERNAME=$3
PASSWORD=$4

DOCKER_NETWORK="database-access"
POSTGRES_CONTAINER="infraxithriuscloud-postgres-1"

check_network
check_postgres_container
check_database_existence $DATABASE_NAME $ELEVATED_USERNAME
create_user_and_grant_privileges $ELEVATED_USERNAME $DATABASE_NAME $USERNAME $PASSWORD

echo "Setup completed successfully."
