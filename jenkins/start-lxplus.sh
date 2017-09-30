#!/bin/sh -x
TARGET=$1
WORKER_USER=$2
WORKER_DIR=$3
DELETE_SLAVE=$4
WORKER_JENKINS_NAME=$5
MAX_WORKSPACE=10
JENKINS_MASTER_ROOT=/var/lib/jenkins
SCRIPT_DIR=`dirname $0`
SSH_OPTS="-q -o IdentitiesOnly=yes -o PubkeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o ServerAliveInterval=60"

if [ `pgrep -f " $TARGET " | grep -v "$$" | wc -l` -gt 1 ] ; then
  exit 99
fi

case $WORKSPACE in
  /tmp/* )
    TMP_SPACE=`ssh -f $SSH_OPTS -n $TARGET df -k /tmp | tail -1 | sed 's|^/[^ ]*  *||' | awk '{print $3}'`
    if [ `echo "$TMP_SPACE/(1024*1024)" | bc` -lt $MAX_WORKSPACE ] ; then exit 99 ; fi
    ;;
esac

REAL_ARCH=`ssh -f $SSH_OPTS -n $TARGET cat /proc/cpuinfo | grep vendor_id | sort | uniq | awk '{print $3}'`
CMS_ARCH=`ssh -f $SSH_OPTS -n $TARGET  sh -c 'cmsos'`

java -jar $JENKINS_MASTER_ROOT/jenkins-cli-2.46.2.jar -i /home/jenkins/.ssh/id_dsa -s http://localhost:8080/jenkins -remoting groovy $SCRIPT_DIR/lxplus-labels.groovy $WORKER_JENKINS_NAME "$REAL_ARCH" $DELETE_SLAVE `echo $TARGET | sed 's|.*@||'` $CMS_ARCH
ssh -f $SSH_OPTS -n $TARGET "mkdir -p $WORKSPACE $WORKER_DIR/foo $WORKER_DIR/cache; rm -rf $WORKSPACE/workspace; ls -d $WORKER_DIR/* | grep -v $WORKER_DIR/cache | xargs rm -rf ; rm -rf /tmp/??"
ssh -f $SSH_OPTS $TARGET mkdir -p $WORKSPACE/workspace
ssh -f $SSH_OPTS $TARGET rm -f $WORKER_DIR/$WORKER_USER.keytab
scp -p $SSH_OPTS $JENKINS_MASTER_ROOT/slave.jar $TARGET:$WORKER_DIR/slave.jar
sleep 1
ssh $SSH_OPTS $TARGET java -jar $WORKER_DIR/slave.jar -jar-cache $WORKER_DIR/cache
