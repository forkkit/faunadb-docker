#!/usr/bin/env sh

export FAUNADB_JAR="/faunadb/lib/faunadb.jar"
export FAUNADB_CONFIG="/etc/faunadb.yml"

/faunadb/bin/faunadb-admin "$@"
