#!/usr/bin/env bash

set -e # Exit in case of any error

err_report() {
	echo "$2 -> Error on line $1 with $3"
}

trap 'err_report $LINENO ${BASH_SOURCE[$i]} ${BASH_COMMAND}' ERR

BASEDIR=`dirname $0`/..
VERSION=`cat $BASEDIR/VERSION`
PKG=$BASEDIR/dist/toree-${VERSION}.tar.gz

echo "Uploading to Nexus..."
curl -u stratio:${NEXUSPASS} --upload-file $PKG http://sodio.stratio.com/nexus/content/sites/paas/toree/${VERSION}/
