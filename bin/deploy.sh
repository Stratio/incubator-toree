#!/usr/bin/env bash

set -e # Exit in case of any error

err_report() {
	  echo "$2 -> Error on line $1 with $3"
}

trap 'err_report $LINENO ${BASH_SOURCE[$i]} ${BASH_COMMAND}' ERR

BASEDIR=`dirname $0`/..

# VERSION Env variable is set by makefile when calling the script
PKG=$BASEDIR/dist/toree-bin/toree-${VERSION}.tar.gz

echo "Uploading to Nexus..."
curl -u stratio:${NEXUSPASS} --upload-file $PKG http://sodio.stratio.com/nexus/content/sites/paas/toree/${VERSION}/
