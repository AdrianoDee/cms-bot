#!/bin/sh -ex
TARGET=$1
CLEANUP_WORKSPACE=$2
SSH_OPTS="-q -o IdentitiesOnly=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o ServerAliveInterval=60"

#Check unique slave conenction
if [ "${SLAVE_UNIQUE_TARGET}" = "YES" ] ; then
  if [ `pgrep -f " ${TARGET} " | grep -v "$$" | wc -l` -gt 1 ] ; then
    exit 99
  fi
fi

#Check slave workspace size in GB
if [ "${SLAVE_MAX_WORKSPACE_SIZE}" != "" ] ; then
  TMP_SPACE=$(ssh -f $SSH_OPTS -n $TARGET df -k $(dirname $WORKSPACE) | tail -1 | sed 's|^/[^ ]*  *||' | awk '{print $3}')
  if [ $(echo "$TMP_SPACE/(1024*1024)" | bc) -lt $SLAVE_MAX_WORKSPACE_SIZE ] ; then exit 99 ; fi
fi

SCRIPT_DIR=`dirname $0`
if [ "${CLEANUP_WORKSPACE}" = "cleanup" ] ; then ssh -n $SSH_OPTS $TARGET rm -rf $WORKSPACE ; fi
ssh -n $SSH_OPTS $TARGET mkdir -p $WORKSPACE/tmp $WORKSPACE/workspace
ssh -n $SSH_OPTS $TARGET rm -f $WORKSPACE/cmsos $WORKSPACE/slave.jar
REMOTE_USER_ID=$(ssh -n $SSH_OPTS $TARGET id -u)
KRB5_FILENAME=$(echo $KRB5CCNAME | sed 's|^FILE:||')
JENKINS_CLI_OPTS="-jar ${HOME}/jenkins-cli.jar -i ${HOME}/.ssh/id_dsa -s http://localhost:8080/$(cat ${HOME}/jenkins_prefix) -remoting"
xenv=""
if [ $(cat ${HOME}/nodes/${JENKINS_SLAVE_NAME}/config.xml | grep '<label>' | grep 'no_label' | wc -l) -eq 0 ] ; then
  case ${SLAVE_TYPE} in
  *dmwm* ) echo "Skipping auto labels" ;;
  aiadm* ) echo "Skipping auto labels" ; xenv="env";;
  lxplus* )
    xenv="env"
    scp -p $SSH_OPTS ${HOME}/cmsos $TARGET:$WORKSPACE/cmsos
    HOST_ARCH=$(ssh -n $SSH_OPTS $TARGET cat /proc/cpuinfo 2> /dev/null | grep vendor_id | sed 's|.*: *||' | tail -1)
    HOST_CMS_ARCH=$(ssh -n $SSH_OPTS $TARGET sh $WORKSPACE/cmsos 2>/dev/null)
    case ${HOST_CMS_ARCH} in 
      slc6_*) lxplus_type="lxplus6";;
      slc7_*) lxplus_type="lxplus7";;
    esac
    if [ "${CLEANUP_WORKSPACE}" != "cleanup" ] ; then
      new_labs="lxplus-scripts ${lxplus_type}-scripts"
    else
      new_labs="${lxplus_type} ${HOST_CMS_ARCH}-lxplus ${HOST_CMS_ARCH}-${lxplus_type} ${HOST_ARCH}"
    fi
    java ${JENKINS_CLI_OPTS} groovy $SCRIPT_DIR/set-slave-labels.groovy "${JENKINS_SLAVE_NAME}" "${new_labs} $(echo $TARGET | sed 's|.*@||')"
    ;;
  * )
    scp -p $SSH_OPTS ${HOME}/cmsos $TARGET:$WORKSPACE/cmsos
    HOST_ARCH=$(ssh -n $SSH_OPTS $TARGET cat /proc/cpuinfo 2>/dev/null | grep vendor_id | sed 's|.*: *||' | tail -1)
    HOST_CMS_ARCH=$(ssh -n $SSH_OPTS $TARGET sh $WORKSPACE/cmsos 2>/dev/null )
    DOCKER_V=$(ssh -n $SSH_OPTS $TARGET docker --version 2>/dev/null || true)
    DOCKER=""
    if [ "${DOCKER_V}" != "" ] ; then
      if [ $(ssh -n $SSH_OPTS $TARGET id -Gn 2>/dev/null | grep docker | wc -l) -gt 0 ] ; then
        DOCKER="docker"
        DOCKER_OS=$(grep -A1 '> *DOCKER_IMG_HOST *<' ${HOME}/nodes/${JENKINS_SLAVE_NAME}/config.xml | tail -1 | sed 's|.*cmssw/||;s|-.*||;s|cc7|slc7|')
        if [ "$DOCKER_OS" != "" ] ; then
          HOST_CMS_ARCH="${DOCKER_OS}_$(echo $HOST_CMS_ARCH | sed 's|^.*_||')"
        fi
      fi
    fi
    new_labs="auto-label ${DOCKER} ${HOST_ARCH} ${HOST_CMS_ARCH}"
    case ${SLAVE_TYPE} in
      cmsbuild*|vocms* ) new_labs="${new_labs} cloud cmsbuild release-build";;
      cmsdev*   ) new_labs="${new_labs} cloud cmsdev";;
    esac
    case ${HOST_CMS_ARCH} in
      *_aarch64|*_ppc64le ) new_labs="${new_labs} release-build cmsbuild";;
    esac
    for p in $(echo ${HOST_CMS_ARCH} | tr '_' ' ') ; do
      new_labs="${new_labs} ${p}"
    done
    java ${JENKINS_CLI_OPTS} groovy ${SCRIPT_DIR}/set-slave-labels.groovy "${JENKINS_SLAVE_NAME}" "${new_labs}"
    ;;
  esac
fi
if ! ssh -n $SSH_OPTS $TARGET test -f '~/.jenkins-slave-setup' ; then
  java ${JENKINS_CLI_OPTS} build 'jenkins-test-slave' -p SLAVE_CONNECTION=${TARGET} -p RSYNC_SLAVE_HOME=true -s || true
fi
scp -p $SSH_OPTS ${HOME}/slave.jar $TARGET:$WORKSPACE/slave.jar
scp -p $SSH_OPTS ${KRB5_FILENAME} $TARGET:/tmp/krb5cc_${REMOTE_USER_ID}
ssh $SSH_OPTS $TARGET "$xenv KRB5CCNAME=FILE:/tmp/krb5cc_${REMOTE_USER_ID} java -jar $WORKSPACE/slave.jar -jar-cache $WORKSPACE/tmp"
