# FaunaDB Developer Image for Windows

Buildchain used to create our Windows-based enterprise Docker image.

## Requirements

- Docker for Windows 17.06.0-ce or higher
- Powershell _(build only)_
- AWS CLI _(build only)_

## How to build

_Windows images are exclusive to Windows and both must be run and built on a
Windows machine._

Run `make.ps1` with the version and package version that you wish to build a package
for. The script will fetch the build from S3 and generate the Docker image.

```powershell
.\make.ps1 FAUNADB_VERSION=<version> FAUNADB_PKG_VERSION=<package version> FAUNADB_JDK_VERSION=<jdk version>
```

## How to use

Once built, you can run FaunaDB interactively with:

```batch
docker run -it --rm \
  -v "$PWD\storage\data:C:\storage\data" \
  -v "$PWD\storage\log:C:\storage\log" \
  faunadb/enterprise:<version>-windows
```

If you want to run FaunaDB in the background, run:

```batch
docker run -d \
  -v "$PWD\storage\data:C:\storage\data" \
  -v "$PWD\storage\log:C:\storage\log" \
  faunadb/enterprise:<version>-windows
```

The Windows image differs from the Linux-based images in that FaunaDB does not
listen on the loopback IP. Instead, you will have to use the docker container's
IP address, which can be found via the following command:

```batch
docker inspect --format '{{ .NetworkSettings.Networks.nat.IPAddress }}' <container id>
```

If you do not know the container's id, you can obtain it via `docker ps`. It can
also be saved to a file by providing the `--cidfile` parameter to the
`docker run` command.

After you obtain the container's IP, you can access the FaunaDB Query API over
HTTP on port `8443`. The default root key is `secret`.
