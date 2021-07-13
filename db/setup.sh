#!/bin/bash
set -e
if ! psql -lqt | cut -d \| -f 1 | grep -qw vrf; then
    echo "Database vrf does not exist, creating..."

    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE DATABASE vrf;"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d vrf < /vrf-db/vrf-db.sql
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE ROLE vrf LOGIN  password '$VRF_PASSWORD'"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d vrf <<-EOSQL
    GRANT ALL PRIVILEGES ON DATABASE vrf to vrf;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public to vrf;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public to vrf;
    GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public to vrf;
EOSQL

else
    echo "Database vrf already exists doing nothing."
fi
