
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

.PHONY: help all change-version clean compile package deploy test integration-test info

# -----------------------------------------------------------------------
#  Variables
# -----------------------------------------------------------------------

VERSION := $(shell cat VERSION)

APACHE_SPARK_VERSION?=1.6.2
SCALA_VERSION?=2.11.7
SCALA_BINARY_VERSION?=2.11
ENV_OPTS:=APACHE_SPARK_VERSION=$(APACHE_SPARK_VERSION) VERSION=$(VERSION)
ASSEMBLY_JAR:=toree-kernel-assembly-$(VERSION)$(SNAPSHOT).jar

# -----------------------------------------------------------------------
#  make help
# -----------------------------------------------------------------------
help:
	@echo '             clean - clean build files'
	@echo '           compile - compile code'
	@echo '           package - builds assembly'
	@echo '              test - execute unit tests'
	@echo '  integration-test - execute integration tests'
	@echo '            deploy - deploy to repositories'
	@echo '    change-version - update version'

# -----------------------------------------------------------------------
#  make all
# -----------------------------------------------------------------------
all: clean compile test package deploy

# -----------------------------------------------------------------------
#  make info
# -----------------------------------------------------------------------
info:
	@echo "$(VERSION)"

# -----------------------------------------------------------------------
#  make clean
# -----------------------------------------------------------------------
clean:
	$(ENV_OPTS) sbt ++$(SCALA_VERSION) clean

# -----------------------------------------------------------------------
#  make compile
# -----------------------------------------------------------------------
compile: VM_WORKDIR=/src/toree-kernel
compile:
		$(ENV_OPTS) sbt ++$(SCALA_VERSION) compile

# -----------------------------------------------------------------------
#  make package
# -----------------------------------------------------------------------
kernel/target/scala-${SCALA_BINARY_VERSION}/$(ASSEMBLY_JAR): VM_WORKDIR=/src/toree-kernel
kernel/target/scala-${SCALA_BINARY_VERSION}/$(ASSEMBLY_JAR): ${shell find ./*/src/main/**/*}
kernel/target/scala-${SCALA_BINARY_VERSION}/$(ASSEMBLY_JAR): ${shell find ./*/build.sbt}
kernel/target/scala-${SCALA_BINARY_VERSION}/$(ASSEMBLY_JAR): project/build.properties project/Build.scala project/Common.scala project/plugins.sbt
	$(ENV_OPTS) sbt ++$(SCALA_VERSION) toree-kernel/assembly

package: kernel/target/scala-${SCALA_BINARY_VERSION}/$(ASSEMBLY_JAR)
package: VERSION_FILE=dist/toree/VERSION
package: kernel/target/scala-${SCALA_BINARY_VERSION}/$(ASSEMBLY_JAR) ${shell find ./etc/bin/*}
	@mkdir -p dist/toree/bin dist/toree/lib
	@cp -r etc/bin/* dist/toree/bin/.
	@cp kernel/target/scala-${SCALA_BINARY_VERSION}/$(ASSEMBLY_JAR) dist/toree/lib/.
	@echo "VERSION: $(VERSION)" > $(VERSION_FILE)
	@(cd dist; tar -cvzf toree-$(VERSION).tar.gz toree)

# -----------------------------------------------------------------------
#  make test
# -----------------------------------------------------------------------
test: VM_WORKDIR=/src/toree-kernel
test:
	$(ENV_OPTS) sbt ++$(SCALA_VERSION) compile test

# -----------------------------------------------------------------------
#  make integration-test
# -----------------------------------------------------------------------
integration-test:
	@echo "Nothing to be done here."

# -----------------------------------------------------------------------
#  make deploy
# -----------------------------------------------------------------------
deploy:
	@echo "Nothing to be done here."
	@echo "$(VERSION)"

# -----------------------------------------------------------------------
#  make change-version
# -----------------------------------------------------------------------
change-version:
	echo "Modifying version to: $(version)"
	echo $(version) > VERSION
