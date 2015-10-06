#!/bin/bash -ex
voms-proxy-init -valid 24:00
export X509_USER_PROXY=/tmp/x509up_u`id -u`

if [ "X$DOCKER_IMG" != X ]; then
  DOCK_ARGS="kinit cmsbuild@CERN.CH -k -t /home/cmsbuild/cmsbuild.keytab || true; cd $WORKSPACE; $@"
  echo "Passing to docker the args: "$DOCK_ARGS
  docker run -h `hostname` \
    -v /etc/localtime:/etc/localtime:ro \
    -v /build/cmsbuild:/build/cmsbuild \
    -v /home/cmsbuild:/home/cmsbuild \
    -v /cvmfs:/cvmfs \
    -v /afs:/afs \
    -e WORKSPACE=$WORKSPACE \
    -e BUILD_NUMBER=$BUILD_NUMBER \
    -e X509_USER_PROXY=$X509_USER_PROXY \
    -e PYTHONPATH=/afs/cern.ch/user/c/cmsbuild/public/pygithub/lib/python2.6/site-packages \
    $DOCKER_IMG sh -c "$DOCK_ARGS"
else
  eval $@
fi
