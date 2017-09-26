#!/bin/sh -ex
TARGET=$1
WORKER_USER=${2-cmsbuild}
WORKER_DIR=${3-/build1/cmsbuild}
JENKINS_MASTER_ROOT=/var/lib/jenkins
SCRIPT_DIR=`dirname $0`
set +x
JENKINS_NODE=$(grep "${TARGET}" ${JENKINS_MASTER_ROOT}/nodes/*/config.xml | sed 's|/config.xml:.*||;s|.*/||' | tail -1)
set -x
if [ $(echo $TARGET | grep '@aiadm' | wc -l) -gt 0 ] ; then
  AIADM_NODE=$(host aiadm | grep 'has address' | sed 's|.* ||' | head -1 | xargs host | sed 's|.* ||;s|\.*$||')
  TARGET=$(echo $TARGET | sed "s|@aiadm.*|@AIADM_NODE|")
fi
kinit cmsbuild@CERN.CH -k -t ${JENKINS_MASTER_ROOT}/cmsbuild.keytab
SSH_OPTS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o ServerAliveInterval=60"
ssh -n $SSH_OPTS $TARGET mkdir -p $WORKSPACE/tmp
ssh -n $SSH_OPTS $TARGET mkdir -p $WORKER_DIR
ssh -n $SSH_OPTS $TARGET rm -f $WORKER_DIR/cmsos
scp -p $SSH_OPTS ${JENKINS_MASTER_ROOT}/slave.jar $TARGET:$WORKER_DIR/slave.jar
scp -p $SSH_OPTS ${JENKINS_MASTER_ROOT}/cmsos $TARGET:$WORKER_DIR/cmsos
HOST_ARCH=`ssh -n $SSH_OPTS $TARGET cat /proc/cpuinfo | grep vendor_id | sed 's|.*: *||' | tail -1`
HOST_CMS_ARCH=`ssh -n $SSH_OPTS $TARGET sh $WORKER_DIR/cmsos`
DOCKER=`ssh -n $SSH_OPTS $TARGET docker --version 2>/dev/null || true`
if [ "X${DOCKER}" != "X" ] ; then DOCKER="docker" ; fi
WORKER_JENKINS_NAME=`echo $TARGET | sed s'|.*@||;s|\..*||'`
case $TARGET in
  *dmwm* ) echo "Skipping auto labels" ;;
  * ) java -jar ${JENKINS_MASTER_ROOT}/jenkins-cli-2.46.2.jar -s http://localhost:8080/jenkins -remoting groovy ${SCRIPT_DIR}/add-cpu-labels.groovy "${JENKINS_NODE}" "$HOST_ARCH" "$HOST_CMS_ARCH" "${DOCKER}" ;;
esac
if ! ssh -n $SSH_OPTS $TARGET test -f '~/.jenkins-slave-setup' ; then
  java -jar ${JENKINS_MASTER_ROOT}/jenkins-cli-2.46.2.jar -s http://localhost:8080/jenkins/ -remoting build 'test-jenkins-host' -p SLAVE_CONNECTION=${TARGET} -p RSYNC_SLAVE_HOME=true -s || true
fi
ssh $SSH_OPTS $TARGET java -jar $WORKER_DIR/slave.jar -jar-cache $WORKSPACE/tmp
