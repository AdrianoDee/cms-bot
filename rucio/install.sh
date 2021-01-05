#!/bin/bash -ex
source /cvmfs/cms.cern.ch/cmsset_default.sh
PYTHON_CMD="python"
INSTALL_DIR=$(/bin/pwd)
SET_CURRENT=false
RUCIO_VERSION=""
PIP_PKG=rucio-clients
DEPS=""
REINSTALL=false
RUN_TESTS=true
ARCH=$(uname -m)/$(cmsos | cut -d_ -f1)

while [ $# -gt 0 ]; do
  case $1 in
    -s|--skip-tests )       RUN_TESTS=false       ;        shift;;
    -r|--reinstall )        REINSTALL=true        ;        shift;;
    -i|--install-dir )      INSTALL_DIR="$2"      ; shift; shift;;
    -c|--current )          SET_CURRENT=true      ;        shift;;
    -v|--rucio-version )    RUCIO_VERSION="$2"    ; shift; shift;;
    -d|--dependency)        DEPS="$2"             ; shift; shift;;
    -p|--python)            PYTHON_CMD="$2"       ; shift; shift;;
    -h|--help )
      echo "
Usage: ${PIP_PKG}-$(basename $0)
  -r|--reinstall                Reinstall the version if already installed
  -i|--install-dir <path>       Install ${PIP_PKG} under <path>.
                                Default is currect working directory
  -v|--rucio-version <version>  ${PIP_PKG} version to install
                                Default is latest available version
  -d|--dependency               Install extra dependencies e.g. urllib3==1.25 requests=1.0
  -c|--current                  Make this version the default version
  -p|--python <python|python3>  Python env to use
  -s|--skip-tests               Do not run rucio tests
  -h|-help                      Show this help message

  It will install ${PIP_PKG} version under ${INSTALL_DIR} and will
  create a symlink 'current' pointing to this version. Run setup.sh
  script to set the ${PIP_PKG} environment e.g
      source ${INSTALL_DIR}/setup.sh
      source ${INSTALL_DIR}/setup.sh <version>"
      exit 0 ;;
    * ) echo "Error: Unknown arg '$1'"; exit 1;;
  esac
done

if [ "${RUCIO_VERSION}" = "" ] ; then
  echo "Error: Missing ${PIP_PKG} version. Please use -v <version> command-line option"
  exit 1
fi

PY_VER=$(${PYTHON_CMD} -c 'import sys;print(sys.version_info[0])')
export PYTHONUSERBASE="${INSTALL_DIR}/${ARCH}/py${PY_VER}/${RUCIO_VERSION}"
if $REINSTALL ; then rm -rf ${PYTHONUSERBASE} ; fi
if [ ! -d ${PYTHONUSERBASE} ] ; then
  mkdir -p "${PYTHONUSERBASE}" "${INSTALL_DIR}/tmp"
  export TMPDIR="${INSTALL_DIR}/tmp"
  if [ $(which ${PYTHON_CMD} | grep '^/usr/bin/' | wc -l) -gt 0 ] ; then
    export PATH=${PYTHONUSERBASE}/bin:$PATH
    ${PYTHON_CMD} -m pip install --upgrade --user pip
    mv ${PYTHONUSERBASE}/bin ${PYTHONUSERBASE}/pip-bin
    export PATH=${PYTHONUSERBASE}/pip-bin:$PATH
    [ "$DEPS" ] && pip install --upgrade --user $DEPS
    pip install --upgrade --user setuptools
  fi
  PATH="${PYTHONUSERBASE}/bin:$PATH" pip install --disable-pip-version-check --user ${PIP_PKG}==${RUCIO_VERSION}
  rm -rf ${TMPDIR}
fi

rm -f ${INSTALL_DIR}/rucio.cfg
cp $(dirname $0)/rucio.cfg ${INSTALL_DIR}/rucio.cfg
rm -f ${PYTHONUSERBASE}/etc/rucio.cfg
ln -s ../../../../../rucio.cfg ${PYTHONUSERBASE}/etc/rucio.cfg

cp -r $(dirname $0)/setup.sh ${INSTALL_DIR}/setup-py${PY_VER}.sh
sed -i -e "s|/\${ARCH}/|/\${ARCH}/py${PY_VER}|" ${INSTALL_DIR}/setup-py${PY_VER}.sh
chmod 0644 ${INSTALL_DIR}/setup-py${PY_VER}.sh
touch ${PYTHONUSERBASE}/.cvmfscatalog

#Testing new version
source ${INSTALL_DIR}/setup-py${PY_VER}.sh ${RUCIO_VERSION}
if [ ${PY_VER} = "2" ] ; then
  ln -sf setup-py${PY_VER}.sh ${INSTALL_DIR}/setup-new.sh
fi

if $RUN_TESTS ; then
  voms-proxy-init
  export RUCIO_ACCOUNT=$(voms-proxy-info | grep '^subject' | sed 's|.*Users/CN=||;s|/.*||')
  rucio list-dataset-replicas cms:/DYJetsToLL_M-50_TuneCP5_13TeV-madgraphMLM-pythia8/RunIIAutumn18NanoAODv5-Nano1June2019_102X_upgrade2018_realistic_v19-v1/NANOAODSIM
  rucio list-rules --account ${RUCIO_ACCOUNT}
  rucio list-account-limits ${RUCIO_ACCOUNT}
  rucio list-rse-attributes T2_IT_Bari
  rucio list-rse-attributes T2_CH_CERN
  rucio list-rse-attributes T2_US_Caltech
  rm -rf $RUCIO_ACCOUNT
fi

[ ! -e ${INSTALL_DIR}/${ARCH}/current ] && SET_CURRENT=true
if $SET_CURRENT ; then
  rm -f ${INSTALL_DIR}/${ARCH}/py${PY_VER}/current
  ln -s ${RUCIO_VERSION} ${INSTALL_DIR}/${ARCH}/py${PY_VER}/current
fi
