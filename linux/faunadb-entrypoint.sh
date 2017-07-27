#!/usr/bin/env sh

# check if arguments starts with --
if [ "$#" -eq 0 ] || [ "${1#--}" != "$1" ]; then
    # prepend default command: faunadb
    set -- faunadb "$@"
fi

exec "$@"

