#!/bin/bash -ex
[ "${CRABCLIENT_TYPE}" != "" ]   || export CRABCLIENT_TYPE="prod"
[ "${BUILD_ID}" != "" ]          || export BUILD_ID=$(date +%s)
[ "${WORKSPACE}" != "" ]         || export WORKSPACE=$(pwd) && cd $WORKSPACE
if [ "${SINGULARITY_IMAGE}" = "" ] ; then
  osver=$(echo ${SCRAM_ARCH} | tr '_' '\n' | head -1 | sed 's|^[a-z][a-z]*||')
  ls /cvmfs/singularity.opensciencegrid.org >/dev/null 2>&1 || true
  IMG_PATH="/cvmfs/singularity.opensciencegrid.org/cmssw/cms:rhel${osver}"
  if [ ! -e "${IMG_PATH}" ] ; then
    IMG_PATH="/cvmfs/unpacked.cern.ch/registry.hub.docker.com/${DOCKER_IMG}-$(uname -m)"
  fi
  export SINGULARITY_IMAGE="${IMG_PATH}"
fi

export CRAB_REQUEST="Jenkins_${CMSSW_VERSION}_${SCRAM_ARCH}_${BUILD_ID}"
voms-proxy-init -voms cms
crab submit -c $(dirname $0)/task.py
mv crab_${CRAB_REQUEST} ${WORKSPACE}/crab

export ID=$(id -u)
export TASK_ID=$(grep crab_${CRAB_REQUEST} $WORKSPACE/crab/.requestcache | sed 's|^V||')

echo "Keep checking job information until grid site has been assigned"
GRIDSITE=""
while [ "${GRIDSITE}" = "" ]
do
  sleep 10
  export GRIDSITE=$(curl -s -X GET --cert "/tmp/x509up_u${ID}" --key "/tmp/x509up_u${ID}" --capath "/etc/grid-security/certificates/" "https://cmsweb.cern.ch:8443/crabserver/prod/task?subresource=search&workflow=${TASK_ID}" | grep -o "http.*/${TASK_ID}")
done

echo "Wait until job has finished"
status=""
while [ "${status}" = "" ]
do
  sleep 300
  curl -s -L -X GET --cert "/tmp/x509up_u${ID}" --key "/tmp/x509up_u${ID}" --capath "/etc/grid-security/certificates/" "${GRIDSITE}/status_cache" > $WORKSPACE/status.log 2>&1
  cat $WORKSPACE/status.log
  errval=$(grep -o "404 Not Found" $WORKSPACE/status.log || echo "")
  cat $WORKSPACE/status.log >> $WORKSPACE/crab/results/logfile
  if [ "$errval" = "" ] ; then
    # Keep checking until job finishes
    status=$(grep -o "'State': 'finished'" $WORKSPACE/status.log || echo "")
  fi
done
echo "PASSED" > $WORKSPACE/crab/statusfile
