#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.	See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.	You may obtain a copy of the License at
#
#		 http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License
#

.PHONY: help clean clean-dist .clean-binder-image .clean-toree-dev-image \
     build dev test system-test test-travis release pip-release bin-release \
     dev-binder \
     audit audit-licenses

BASE_VERSION?=0.6.0
# Env variable version is set by Jenkins, it will be only the Stratio part
FINAL_VERSION=$(BASE_VERSION)-incubating-$(version)
COMMIT=$(shell git rev-parse --short=12 --verify HEAD)

VERSION=$(BASE_VERSION)-incubating
COMMIT=$(shell git rev-parse --short=12 --verify HEAD)
ifeq (, $(findstring dev, $(FINAL_VERSION)))
IS_SNAPSHOT?=false
else
IS_SNAPSHOT?=true
SNAPSHOT:=-SNAPSHOT
endif

APACHE_SPARK_VERSION?=3.0.0
SCALA_VERSION?=2.12
IMAGE?=jupyter/all-spark-notebook:latest
EXAMPLE_IMAGE?=apache/toree-examples
TOREE_DEV_IMAGE?=apache/toree-dev
GPG?=gpg
GPG_PASSWORD?=
BINDER_IMAGE?=apache/toree-binder
DOCKER_WORKDIR?=/srv/toree
DOCKER_ARGS?=
define DOCKER
docker run -t --rm \
	--workdir $(DOCKER_WORKDIR) \
	-e PYTHONPATH='/srv/toree' \
	-v `pwd`:/srv/toree $(DOCKER_ARGS)
endef

define GEN_PIP_PACKAGE_INFO
printf "__version__ = '$(BASE_VERSION)'\n" >> dist/toree-pip/toree/_version.py
printf "__commit__ = '$(COMMIT)'\n" >> dist/toree-pip/toree/_version.py
endef

USE_VAGRANT?=
RUN_PREFIX=$(if $(USE_VAGRANT),vagrant ssh -c "cd $(VM_WORKDIR) && )
RUN_SUFFIX=$(if $(USE_VAGRANT),")

RUN=$(RUN_PREFIX)$(1)$(RUN_SUFFIX)

ENV_OPTS:=APACHE_SPARK_VERSION=$(APACHE_SPARK_VERSION) VERSION=$(FINAL_VERSION) IS_SNAPSHOT=$(IS_SNAPSHOT)

ASSEMBLY_JAR:=toree-assembly-$(FINAL_VERSION)$(SNAPSHOT).jar

help:
	@echo '	'
	@echo '	clean - clean build files'
	@echo '	dist - build a directory with contents to package'
	@echo '	build - builds assembly'
	@echo ' package - builds and creates tar.gz with package'
	@echo ' deploy - uploads the tar.gz package to nexus'
	@echo '	'

download-sbt:
	@wget http://tools.stratio.com/buildtools/sbt-1.2.1.tgz
	@mkdir -p ./build-tools/sbt
	@tar -xzf ./sbt-1.2.1.tgz -C ./build-tools/
	@rm ./sbt-1.2.1.tgz
build: download-sbt
clean: download-sbt

package: build dist bin-release

deploy:
	$(call RUN,$(ENV_OPTS) ./bin/deploy.sh)

# Jenkins needs this target even if it does nothing
change-version:
	@echo 'Noting to do here...'

build-info:
	@echo '$(ENV_OPTS) $(FINAL_VERSION)'

clean-dist:
	-rm -r dist

clean: VM_WORKDIR=/src/toree-kernel
clean: clean-dist
	$(call RUN,$(ENV_OPTS) build-tools/sbt/bin/sbt clean)
	-find . -name target -type d -exec rm -fr {} +
	-find . -name .ipynb_checkpoints  -type d -exec rm -fr {} +

.clean-toree-dev-image:
	@rm -f .toree-dev-image
	@-docker rmi -f $(TOREE_DEV_IMAGE)

.toree-dev-image:
	@docker build -t $(TOREE_DEV_IMAGE) -f Dockerfile.toree-dev .
	touch $@

.clean-binder-image:
	@rm -f .binder-image
	@-docker rmi -f $(BINDER_IMAGE)

.binder-image: .clean-binder-image
	@docker build --rm -t $(BINDER_IMAGE) .
	touch $@

dev-binder: .binder-image
	@docker run --rm -t -p 8888:8888	\
		-v `pwd`:/home/main/notebooks \
		--workdir /home/main/notebooks $(BINDER_IMAGE) \
		/home/main/start-notebook.sh --ip=0.0.0.0

target/scala-$(SCALA_VERSION)/$(ASSEMBLY_JAR): VM_WORKDIR=/src/toree-kernel
target/scala-$(SCALA_VERSION)/$(ASSEMBLY_JAR): ${shell find ./*/src/main/**/*}
target/scala-$(SCALA_VERSION)/$(ASSEMBLY_JAR): ${shell find ./*/build.sbt}
target/scala-$(SCALA_VERSION)/$(ASSEMBLY_JAR): ${shell find ./project/*.scala} ${shell find ./project/*.sbt}
target/scala-$(SCALA_VERSION)/$(ASSEMBLY_JAR): dist/toree-legal project/build.properties build.sbt
	$(call RUN,$(ENV_OPTS) build-tools/sbt/bin/sbt root/assembly)

build: target/scala-$(SCALA_VERSION)/$(ASSEMBLY_JAR)

sbt-%:
	$(call RUN,$(ENV_OPTS) build-tools/sbt/bin/sbt $(subst sbt-,,$@) )

dist/toree/lib: target/scala-$(SCALA_VERSION)/$(ASSEMBLY_JAR)
	@mkdir -p dist/toree/lib
	@cp target/scala-$(SCALA_VERSION)/$(ASSEMBLY_JAR) dist/toree/lib/.

dist/toree/bin: ${shell find ./etc/bin/*}
	@mkdir -p dist/toree/bin
	@cp -r etc/bin/* dist/toree/bin/.

dist/toree/VERSION:
	@mkdir -p dist/toree
	@echo "VERSION: $(FINAL_VERSION)" > dist/toree/VERSION
	@echo "COMMIT: $(COMMIT)" >> dist/toree/VERSION

dist/toree/logo-64x64.png:
	@mkdir -p dist/toree
	@cp -r etc/logo-64x64.png dist/toree/logo-64x64.png

dist/toree-legal/LICENSE: LICENSE etc/legal/LICENSE_extras
	@mkdir -p dist/toree-legal
	@cat LICENSE > dist/toree-legal/LICENSE
	@echo '\n' >> dist/toree-legal/LICENSE
	@cat etc/legal/LICENSE_extras >> dist/toree-legal/LICENSE

dist/toree-legal/NOTICE: NOTICE etc/legal/NOTICE_extras
	@mkdir -p dist/toree-legal
	@cat NOTICE > dist/toree-legal/NOTICE
	@echo '\n' >> dist/toree-legal/NOTICE
	@cat etc/legal/NOTICE_extras >> dist/toree-legal/NOTICE

dist/toree-legal/DISCLAIMER:
	@mkdir -p dist/toree-legal
	@cp DISCLAIMER dist/toree-legal/DISCLAIMER

dist/toree-legal: dist/toree-legal/LICENSE dist/toree-legal/NOTICE dist/toree-legal/DISCLAIMER
	@cp -R etc/legal/licenses dist/toree-legal/.

dist/toree: dist/toree/VERSION dist/toree/logo-64x64.png dist/toree-legal dist/toree/lib dist/toree/bin RELEASE_NOTES.md
	@cp -R dist/toree-legal/* dist/toree
	@cp RELEASE_NOTES.md dist/toree/RELEASE_NOTES.md

dist: dist/toree


################################################################################
# BIN PACKAGE
################################################################################
dist/toree-bin/toree-$(FINAL_VERSION)-binary-release.tar.gz: dist/toree
	@mkdir -p dist/toree-bin
	@(cd dist; tar -cvzf toree-bin/toree-$(FINAL_VERSION).tar.gz toree)

bin-release: dist/toree-bin/toree-$(FINAL_VERSION)-binary-release.tar.gz
