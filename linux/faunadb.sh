#!/usr/bin/env sh

set -e

host_ip=$(hostname -i)
join_node="$host_ip"
action=""
user_config_file=""
custom_replica_name="NoDC"

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
        user_config_file="$2"
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
final_config_path="/etc/faunadb.yml"
template_default_configs="/etc/faunadb.yml.default"

default_admin_http_port=8444
default_admin_http_address="127.0.0.1"

cat > "$template_default_configs" <<EOF
---
auth_root_key: secret
storage_data_path: $default_data_path
log_path: $default_log_path
network_listen_address: $host_ip
network_broadcast_address: $host_ip
network_admin_http_address: $default_admin_http_address #don't expose admin endpoint outside docker by default
network_coordinator_http_address: 0.0.0.0               #expose api endpoint to all interfaces
EOF

list_configs() {
  local file=$1

  sed -n "s/^\(.\+\):[[:space:]]*.\+$/\1/p" "$file" | awk -F# '{print $1}'
}

get_config() {
  local file=$1
  local config=$2
  local default=$3

  value=$(sed -n "s/^$config:[[:space:]]*\(.\+\)$/\1/p" "$file" | awk -F# '{print $1}')
  if [ ! -z "$value" ]; then
    echo "$value"
  else
    echo "$default"
  fi
}

if [ -z "$user_config_file" ]; then
  # if user hasn't specified a config file, just link the default configs
  ln -s "$template_default_configs" "$final_config_path"
else
  # merge user configs with the default configs
  user_configs=$(list_configs "$user_config_file")
  default_configs=$(list_configs "$template_default_configs")
  all_keys=$(printf "$user_configs\n$default_configs" | sort | uniq)

  echo "Merging user configs to $final_config_path..."

  echo "---" > "$final_config_path"
  for config_key in $(echo $all_keys); do
    default_value=$(get_config "$template_default_configs" "$config_key" "")
    config_value=$(get_config "$user_config_file" "$config_key" "$default_value")

    echo "$config_key: $config_value" >> "$final_config_path"
  done
fi

data_path=$(get_config "$final_config_path" storage_data_path "$default_data_path")
log_path=$(get_config "$final_config_path" log_path "$default_log_path")
admin_port=$(get_config "$final_config_path" network_admin_http_port "$default_admin_http_port")
admin_address=$(get_config "$final_config_path" network_admin_http_address "$default_admin_http_address")

mkdir -p "$data_path" "$log_path"

wait_fauna_and_do() {
  while ! curl -s "http://$admin_address:$admin_port" > /dev/null; do
    sleep 1
  done

  eval "$@"
}

init_cluster() {
  echo "Initializing the cluster"
  faunadb-admin -c "$final_config_path" -r $custom_replica_name init
}

join_cluster() {
  echo "Joining the cluster"
  faunadb-admin -c "$final_config_path" join "$1"
}

# no action specified but has an empty data path, so init
if [ -z "$action" ] && [ -z "$(ls -A $data_path)" ]; then
  action="init"
fi

if [ "$action" = "init" ]; then
  if [ -z "$custom_replica_name" ]; then
    echo "Initialization requires a replica name"
    exit 1
  fi

  wait_fauna_and_do init_cluster &
fi

if [ "$action" = "join" ]; then
  wait_fauna_and_do join_cluster "$join_node" &
fi

cd /faunadb

if [ "$UID" -ne 0 ]; then
  if [ "$GID" -eq 0 ]; then
    GID=$UID
  fi
  usermod -u $UID faunadb > /dev/null 2>&1
  groupmod -g $GID faunadb > /dev/null 2>&1

  chown faunadb:faunadb "$data_path" "$log_path"
  exec setuidgid faunadb bin/faunadb -c "$final_config_path"
else
  exec bin/faunadb -c "$final_config_path"
fi
