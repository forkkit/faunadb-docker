ARG JDK_VERSION
# Prepare enterprise package
FROM microsoft/windowsservercore:1803 AS enterprise-package

SHELL ["powershell", "-NonInteractive", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

WORKDIR "C:\\"

ARG PKG_VERSION

COPY faunadb-enterprise-$PKG_VERSION.zip .

RUN Expand-Archive ('faunadb-enterprise-{0}.zip' -f $env:PKG_VERSION) -DestinationPath '.'; \
	Remove-Item ('faunadb-enterprise-{0}.zip' -f $env:PKG_VERSION) -Force; \
	Rename-Item -Path ('faunadb-{0}' -f $env:PKG_VERSION) -NewName 'faunadb-enterprise'

FROM openjdk:$JDK_VERSION-windowsservercore-1803 AS openjdk-package

# Final docker image
FROM microsoft/powershell:windowsservercore-1803

LABEL maintainer="Fauna, Inc. <support@fauna.com>"

WORKDIR faunadb

COPY --from=openjdk-package \
     C:\\openjdk-$JDK_VERSION \
     C:\\java

COPY --from=enterprise-package \
    C:\\faunadb-enterprise \
    C:\\faunadb

COPY faunadb-entrypoint.ps1 faunadb-entrypoint.ps1
COPY faunadb.ps1 faunadb.ps1
COPY faunadb-admin.ps1 faunadb-admin.ps1
COPY helpers.ps1 helpers.ps1

VOLUME "C:\\storage\\data" "C:\\storage\\log" "C:\\configs"

EXPOSE 8443 7500 7501

ENTRYPOINT ["pwsh", "faunadb-entrypoint.ps1"]
CMD [".\\faunadb.ps1"]

ARG PKG_VERSION
ARG VERSION

ENV FAUNADB_VERSION=$VERSION

LABEL faunadb.version=$VERSION \
    faunadb.package=$PKG_VERSION
