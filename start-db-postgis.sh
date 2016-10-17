#!/bin/sh

set -e

#/usr/lib/postgresql/$PG_VERSION/bin/postgres -D /var/lib/postgresql/$PG_VERSION/main/ -c config_file=/etc/postgresql/$PG_VERSION/main/postgresql.conf

# Perform all actions as $POSTGRES_USER
export PGUSER="postgres"

# Create the 'template_postgis' template db
gosu postgres psql <<- 'EOSQL'
CREATE DATABASE template_postgis;
UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template_postgis';
SET search_path TO postgis, public;
EOSQL

# Load PostGIS into both template_database and $POSTGRES_DB
for DB in template_postgis postgres; do
	echo "Loading PostGIS extensions into postgres"
	gosu postgres psql --dbname="postgres" <<-'EOSQL'
		CREATE EXTENSION IF NOT EXISTS postgis;
		CREATE EXTENSION IF NOT EXISTS postgis_topology;
		CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
		CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder;
EOSQL
done

gosu postgres psql <<- 'EOSQL'
SET search_path TO postgis, public;
EOSQL



#
