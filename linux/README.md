# FaunaDB Enterprise Image

Buildchain used to create our FaunaDB Enterprise Docker image.

## Requirements

- Docker 17.06.0-ce or higher
- Make _(build only)_
- AWS CLI _(build only)_

## How to build

Simply run make with the version and package version that you wish to build a
package for. Make will fetch the build from S3 and generate the Docker image.

```bash
$ make FAUNADB_VERSION=<version> FAUNADB_PKG_VERSION=<package version>
```

## How to use

### Pull Docker Image

To get a docker image of FaunaDB, simply run:

```bash
$ docker pull fauna/faunadb:<version>
```

replace `<version>` for the FaunaDB version you are interested.

### Usage

```bash
$ docker run fauna/faunadb:<version> --help
FaunaDB Enterprise Docker Image

Options:
 --help                 Print this message and exit.
 --init                 Initialize the node (default action).
 --run                  Run and doesn't initialize the node.
 --join host[:port]     Join a cluster through an active node specified in host and port.
 --replica_name <name>  Specify a replica name for the node.
 --config <path>        Specify a custom config file. Should be accessible inside the docker image.
```

If you are a developer and want a FaunaDB instance up and running, the simplest way to do it is by running:

```bash
$ docker run --rm --name faunadb -p 8443:8443 fauna/faunadb:<version>
```

### Persisted data

The above command will start a faunadb instance and initialize the cluster, however when you kill the docker container, all your data will be lost.
In order to prevent this you can map a volume to the folder `/var/lib/faunadb` and all data stored in FaunaDB can be persisted among executions.

```bash
$ docker run --rm --name faunadb -p 8443:8443 \
    -v <host-directory or named-volume>:/var/lib/faunadb \
    fauna/faunadb:<version>
```

### FaunaDB logs

To access to FaunaDB logs, you can also map a volume to the folder `/var/log/faunadb`

```bash
$ docker run --rm --name faunadb -p 8443:8443 \
    -v <host-directory or named-volume>:/var/lib/faunadb \
    -v <host-directory>:/var/log/faunadb \
    fauna/faunadb:<version>
```

### FaunaDB config

The previous command will start a FaunaDB instance using the default configurations, if you want however specify your own parameters you would need to map a config file and pass it to the command line 

```bash
$ docker run --rm --name faunadb -p 8443:8443 \
    -v <host-directory or named-volume>:/var/lib/faunadb \
    -v <host-directory>:/var/log/faunadb \
    -v <path-to-config-file>:/etc/faunadb.yml \
    fauna/faunadb:<version> --config /etc/faunadb.yml
```

This is an example config file

```yml
---
auth_root_key: secret
network_datacenter_name: NoDc
storage_data_path: /storage/data
log_path: /storage/log
shutdown_grace_period_seconds: 0
network_listen_address: 172.17.0.2
network_broadcast_address: 172.17.0.2
network_admin_http_address: 172.17.0.2
network_coordinator_http_address: 172.17.0.2
storage_transaction_log_nodes:
 - [ 172.17.0.2 ]
```

For more information about the above configurations and others go to [How to Operate FaunaDB](https://app.fauna.com/documentation/howto/operations/).
