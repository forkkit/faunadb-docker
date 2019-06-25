ARG JDK_VERSION
# Prepare to unarchive fauna package
FROM debian:stretch-slim AS faunadb-package

RUN apt-get update && \
	apt-get install -y unzip && \
	rm -rf /var/lib/apt/lists/*

WORKDIR faunadb

ARG PKG_VERSION

COPY faunadb-$PKG_VERSION.zip faunadb-$PKG_VERSION.zip

RUN unzip -q faunadb-$PKG_VERSION.zip && \
	rm faunadb-$PKG_VERSION.zip && \
	cp -r faunadb-$PKG_VERSION/** . && \
	rm -r faunadb-$PKG_VERSION

# Final docker image
FROM openjdk:$JDK_VERSION-slim
LABEL maintainer="Fauna, Inc. <support@fauna.com>"

ENV UID=0 \
    GID=0

WORKDIR faunadb

RUN apt-get update && \
	apt-get install -y curl daemontools && \
	rm -rf /var/lib/apt/lists/*

RUN useradd -UMd /faunadb faunadb

COPY --from=faunadb-package \
	/faunadb \
	/faunadb

COPY faunadb-admin.sh /usr/local/bin/faunadb-admin
COPY faunadb.sh /usr/local/bin/faunadb
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/faunadb \
    /usr/local/bin/entrypoint.sh \
    /usr/local/bin/faunadb-admin

VOLUME /var/log/faunadb /var/lib/faunadb

EXPOSE 8443 7500 7501

ENTRYPOINT ["entrypoint.sh"]
CMD ["faunadb"]

ARG PKG_VERSION
ARG VERSION

LABEL faunadb.version=$VERSION \
	faunadb.package=$PKG_VERSION
