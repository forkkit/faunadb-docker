#!/usr/bin/env sh

set -e

host_ip=$(hostname -i)
join_node="$host_ip"
action=""
config_file=""
custom_replica_name=""

show_help() {
  cat <<EOF
FaunaDB Enterprise Docker Image

Options:
 --help                 Print this message and exit.
 --init                 Initialize the node (default action).
 --run                  Run and doesn't initialize the node.
 --join host[:port]     Join a cluster through an active node specified in host and port.
 --replica_name <name>  Specify a replica name for the node.
 --config <path>        Specify a custom config file. Should be accessible inside the docker image.
EOF
}

check_action() {
  if [ ! -z "$action" ]; then
    echo "Arguments --init and --join are mutually exclusive"
    exit 1
  fi
}

while [ $# -gt 0 ]; do
  case "$1" in
    --help)
      show_help
      exit 0
    ;;

    --config)
      if [ -z "$2" ]; then
        echo "Argument --config needs a file path."
        exit 1
      else
        config_file="$2"
        shift 1
      fi
      shift 1
    ;;

    --replica_name)
      if [ -z "$2" ]; then
        echo "Argument --replica_name needs a name."
        exit 1
      else
        custom_replica_name="$2"
        shift 1
      fi
      shift 1
    ;;

    --init)
      check_action
      action="init"
      shift 1
    ;;

    --run)
      action="run"
      shift 1
    ;;

    --join)
      if [ -z "$2" ]; then
        echo "Argument --join needs a HOST[:PORT] address to join a cluster. Skip joining."
        echo "Run 'docker exec <container> faunadb-admin --help' for more information."
      else
        check_action
        action="join"
        join_node="$2"
        shift 1
      fi
      shift 1
    ;;

    *)
      echo "Invalid argument: $1"
      exit 0
    ;;
  esac
done

# this is fauna default paths
default_data_path="/var/lib/faunadb"
default_log_path="/var/log/faunadb"

if [ -z "$config_file" ]; then
  config_file="/faunadb/enterprise/default.yml"

  cat > "$config_file" <<EOF
---
auth_root_key: secret
replica_name: ${custom_replica_name:-NoDc}
storage_data_path: $default_data_path
log_path: $default_log_path
network_listen_address: $host_ip
network_broadcast_address: $host_ip
network_admin_http_address: 127.0.0.1     #don't expose admin endpoint outside docker by default
network_coordinator_http_address: 0.0.0.0 #expose api endpoint to all interfaces
EOF
fi

get_config() {
  local config=$1
  local default=$2

  value=$(sed -n "s/^$config:[[:space:]]*\(.\+\)$/\1/p" "$config_file" | awk -F# '{print $1}')
  if [ ! -z "$value" ]; then
    echo "$value"
  else
    echo "$default"
  fi
}

data_path=$(get_config storage_data_path "$default_data_path")
log_path=$(get_config log_path "$default_log_path")
admin_port=$(get_config network_admin_http_port 8444)
admin_address=$(get_config network_admin_http_address "127.0.0.1")

mkdir -p "$data_path" "$log_path"

wait_fauna_and_do() {
  while ! curl -s "http://$admin_address:$admin_port" > /dev/null; do
    sleep 1
  done

  eval "$@"
}

init_cluster() {
  echo "Initializing the cluster"
  faunadb-admin -c "$config_file" init
}

join_cluster() {
  echo "Joining the cluster"
  faunadb-admin -c "$config_file" join "$1"
}

# no action specified but has an empty data path, so init
if [ -z "$action" ] && [ -z "$(ls -A $data_path)" ]; then
  action="init"
fi

if [ "$action" = "init" ]; then
  wait_fauna_and_do init_cluster &
fi

if [ "$action" = "join" ]; then
  wait_fauna_and_do join_cluster "$join_node" &
fi

cd /faunadb/enterprise

echo "$config_file" > .config_file

if [ "$UID" -ne 0 ]; then
  if [ "$GID" -eq 0 ]; then
    GID=$UID
  fi
  usermod -u $UID faunadb > /dev/null 2>&1
  groupmod -g $GID faunadb > /dev/null 2>&1

  chown faunadb:faunadb "$data_path" "$log_path"
  exec setuidgid faunadb bin/faunadb -c "$config_file"
else
  exec bin/faunadb -c "$config_file"
fi
