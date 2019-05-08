EXTRA_TAGS ?=
TAGS := $(FAUNADB_VERSION)-jdk$(FAUNADB_JDK_VERSION) $(EXTRA_TAGS)
define \n


endef

.PHONY: all fetch-release fetch-nightly build publish-release publish-nightly -fetch -has-version -has-pkg-version -has-jdk-version -has-nightly

all: fetch-release build

fetch-release: -has-version -has-pkg-version -fetch

fetch-nightly: -has-nightly -has-pkg-version -fetch

build: -has-version -has-pkg-version -has-jdk-version
	docker build --pull \
		--build-arg VERSION=$(FAUNADB_VERSION) \
		--build-arg PKG_VERSION=$(FAUNADB_PKG_VERSION) \
		--build-arg JDK_VERSION=$(FAUNADB_JDK_VERSION) \
		-t faunadb-enterprise:local .

publish-stable-release: -has-version -has-jdk-version
	$(foreach TAG,$(TAGS),docker tag faunadb-enterprise:local fauna/faunadb:$(TAG)${\n})
	$(foreach TAG,$(TAGS),docker push fauna/faunadb:$(TAG)${\n})
	$(foreach TAG,$(TAGS),docker tag faunadb-enterprise:local gcr.io/faunadb-cloud/faunadb/enterprise/release:$(TAG)${\n})
	$(foreach TAG,$(TAGS),docker push gcr.io/faunadb-cloud/faunadb/enterprise/release:$(TAG)${\n})

publish-unstable-release: -has-version -has-jdk-version
	$(foreach TAG,$(TAGS),docker tag faunadb-enterprise:local fauna/faunadb-unstable:$(TAG)${\n})
	$(foreach TAG,$(TAGS),docker push fauna/faunadb-unstable:$(TAG)${\n})
	$(foreach TAG,$(TAGS),docker tag faunadb-enterprise:local gcr.io/faunadb-cloud/faunadb/enterprise/unstable:$(TAG)${\n})
	$(foreach TAG,$(TAGS),docker push gcr.io/faunadb-cloud/faunadb/enterprise/unstable:$(TAG)${\n})

publish-nightly: -has-version -has-jdk-version
	$(foreach TAG,$(TAGS),docker tag faunadb-enterprise:local gcr.io/faunadb-cloud/faunadb/enterprise/nightly:$(TAG)${\n})
	$(foreach TAG,$(TAGS),docker push gcr.io/faunadb-cloud/faunadb/enterprise/nightly:$(TAG)${\n})

-fetch: faunadb-enterprise-$(FAUNADB_PKG_VERSION).zip

faunadb-enterprise-$(FAUNADB_PKG_VERSION).zip:
	aws s3 cp $(package_url)/faunadb-enterprise-$(FAUNADB_PKG_VERSION).zip .

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

-has-nightly:
ifndef FAUNADB_NIGHTLY
	$(error FAUNADB_NIGHTLY is undefined)
endif

define package_url
$(if $(FAUNADB_NIGHTLY),s3://fauna-nightly/$(FAUNADB_NIGHTLY),s3://fauna-releases/builds/enterprise/$(FAUNADB_VERSION))
endef
