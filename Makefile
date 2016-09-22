#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License
#

.PHONY: help clean build test bin-release

# -----------------------------------------------------------------------
#  Variables
# -----------------------------------------------------------------------
VERSION?=0.1.0.stratio.dev4
COMMIT=$(shell git rev-parse --short=12 --verify HEAD)
ifeq (, $(findstring dev, $(VERSION)))
IS_SNAPSHOT?=false
else
IS_SNAPSHOT?=true
SNAPSHOT:=-SNAPSHOT
endif

APACHE_SPARK_VERSION?=1.6.2
SCALA_VERSION?=2.11.7
SCALA_BINARY_VERSION?=2.11
ENV_OPTS:=APACHE_SPARK_VERSION=$(APACHE_SPARK_VERSION) VERSION=$(VERSION) IS_SNAPSHOT=$(IS_SNAPSHOT)
ASSEMBLY_JAR:=toree-kernel-assembly-$(VERSION)$(SNAPSHOT).jar

# -----------------------------------------------------------------------
#  make help
# -----------------------------------------------------------------------
help:
	@echo '      clean - clean build files'
	@echo '       dist - build a directory with contents to package'
	@echo '      build - builds assembly'
	@echo '       test - run all units'

# -----------------------------------------------------------------------
#  make clean
# -----------------------------------------------------------------------
clean:
	$(ENV_OPTS) sbt ++$(SCALA_VERSION) clean

# -----------------------------------------------------------------------
#  make build
# -----------------------------------------------------------------------
kernel/target/scala-${SCALA_BINARY_VERSION}/$(ASSEMBLY_JAR): VM_WORKDIR=/src/toree-kernel
kernel/target/scala-${SCALA_BINARY_VERSION}/$(ASSEMBLY_JAR): ${shell find ./*/src/main/**/*}
kernel/target/scala-${SCALA_BINARY_VERSION}/$(ASSEMBLY_JAR): ${shell find ./*/build.sbt}
kernel/target/scala-${SCALA_BINARY_VERSION}/$(ASSEMBLY_JAR): project/build.properties project/Build.scala project/Common.scala project/plugins.sbt
	$(ENV_OPTS) sbt ++$(SCALA_VERSION) toree-kernel/assembly

build: kernel/target/scala-${SCALA_BINARY_VERSION}/$(ASSEMBLY_JAR)

# -----------------------------------------------------------------------
#  make test
# -----------------------------------------------------------------------
test: VM_WORKDIR=/src/toree-kernel
test:
	$(ENV_OPTS) sbt ++$(SCALA_VERSION) compile test

# -----------------------------------------------------------------------
#  make dist
# -----------------------------------------------------------------------
dist: VERSION_FILE=dist/toree/VERSION
dist: kernel/target/scala-${SCALA_BINARY_VERSION}/$(ASSEMBLY_JAR) ${shell find ./etc/bin/*}
	@mkdir -p dist/toree/bin dist/toree/lib
	@cp -r etc/bin/* dist/toree/bin/.
	@cp kernel/target/scala-${SCALA_BINARY_VERSION}/$(ASSEMBLY_JAR) dist/toree/lib/.
	@echo "VERSION: $(VERSION)" > $(VERSION_FILE)

# -----------------------------------------------------------------------
    #  make bin-release
# -----------------------------------------------------------------------
bin-release: dist
	@(cd dist; tar -cvzf toree-$(VERSION)-binary-release.tar.gz toree)
