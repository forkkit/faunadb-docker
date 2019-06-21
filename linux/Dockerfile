ARG JDK_VERSION
# Prepare enterprise package
FROM debian:stretch-slim AS enterprise-package

RUN apt-get update && \
	apt-get install -y unzip && \
	rm -rf /var/lib/apt/lists/*

WORKDIR faunadb-enterprise

ARG PKG_VERSION

COPY faunadb-enterprise-$PKG_VERSION.zip faunadb-enterprise-$PKG_VERSION.zip

RUN unzip -q faunadb-enterprise-$PKG_VERSION.zip && \
	rm faunadb-enterprise-$PKG_VERSION.zip && \
	cp -r faunadb-$PKG_VERSION/** . && \
	rm -r faunadb-$PKG_VERSION

# Final docker image
FROM openjdk:$JDK_VERSION-slim
LABEL maintainer="Fauna, Inc. <support@fauna.com>"

ENV UID=0 \
    GID=0

WORKDIR faunadb

RUN apt-get update && \
     apt install -y curl daemontools
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
     && apt-get install nodejs -y \
      && npm install -g fauna-shell \
	&& rm -rf /var/lib/apt/lists/*

RUN useradd -UMd /faunadb faunadb

COPY --from=enterprise-package \
	/faunadb-enterprise \
	enterprise/

COPY faunadb-admin-wrapper /usr/local/bin/faunadb-admin
COPY faunadb-enterprise.sh /usr/local/bin/faunadb
COPY faunadb-entrypoint.sh /usr/local/bin/faunadb-entrypoint.sh
RUN chmod +x /usr/local/bin/faunadb \
    /usr/local/bin/faunadb-entrypoint.sh \
    /usr/local/bin/faunadb-admin

VOLUME /var/log/faunadb /var/lib/faunadb

EXPOSE 8443 7500 7501

ENTRYPOINT ["faunadb-entrypoint.sh"]
CMD ["faunadb"]

ARG PKG_VERSION
ARG VERSION

LABEL faunadb.version=$VERSION \
	faunadb.package=$PKG_VERSION
