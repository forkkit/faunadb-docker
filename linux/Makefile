local_tag := $(FAUNADB_VERSION)-jdk$(FAUNADB_JDK_VERSION)
local_image := faunadb-local:$(local_tag)
package_url := s3://fauna-releases/builds/enterprise/$(FAUNADB_VERSION)

EXTRA_TAGS ?=
TAGS := $(local_tag) $(EXTRA_TAGS)

define \n


endef

.PHONY: all fetch-release build publish-release publish-nightly -fetch -has-version -has-pkg-version -has-jdk-version

all: fetch-release build

fetch-release: -has-version -has-pkg-version -fetch

build: -has-version -has-pkg-version -has-jdk-version
	docker build --pull \
		--build-arg VERSION=$(FAUNADB_VERSION) \
		--build-arg PKG_VERSION=$(FAUNADB_PKG_VERSION) \
		--build-arg JDK_VERSION=$(FAUNADB_JDK_VERSION) \
		-t $(local_image) .

build-latest-graphql: TAG ?= "fauna/faunadb-graphql:latest"
build-latest-graphql: 
	docker build --pull \
		--build-arg GRAPHQL_IMAGE=gcr.io/faunadb-cloud/faunadb/extensions/graphql:latest \
		--build-arg FAUNADB_IMAGE=fauna/faunadb:latest \
		-f Dockerfile-graphql -t $(TAG) .

publish-stable-release: -has-version -has-jdk-version
	$(call push_image,fauna/faunadb)
	$(call push_image,gcr.io/faunadb-cloud/faunadb/enterprise/release)

publish-unstable-release: -has-version -has-jdk-version
	$(call push_image,fauna/faunadb-unstable)
	$(call push_image,gcr.io/faunadb-cloud/faunadb/enterprise/unstable)

publish-nightly-release: -has-version -has-jdk-version
	$(call push_image,gcr.io/faunadb-cloud/faunadb/enterprise/nightly)

publish-nightly: publish-nightly-release

-fetch: faunadb-$(FAUNADB_PKG_VERSION).zip

faunadb-$(FAUNADB_PKG_VERSION).zip:
	aws s3 cp $(package_url)/faunadb-$(FAUNADB_PKG_VERSION).zip .

-has-version:
ifndef FAUNADB_VERSION
	$(error FAUNADB_VERSION is undefined)
endif

-has-pkg-version:
ifndef FAUNADB_PKG_VERSION
	$(error FAUNADB_PKG_VERSION is undefined)
endif

-has-jdk-version:
ifndef FAUNADB_JDK_VERSION
	$(error FAUNADB_JDK_VERSION is undefined)
endif

define push_image
	$(foreach TAG,$(TAGS),docker tag $(local_image) $(1):$(TAG)${\n})
	$(foreach TAG,$(TAGS),docker push $(1):$(TAG)${\n})
endef

