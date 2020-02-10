#!/usr/bin/env sh

# check if arguments starts with --
if [ "$#" -eq 0 ] || [ "${1#--}" != "$1" ]; then
    # prepend default command: faunadb
    set -- faunadb "$@"
fi

env FAUNADB_ENDPOINT=http://localhost:8443 FAUNADB_SECRET=secret \
	java -jar lib/faunadb-graphql-api.jar &

exec "$@"
