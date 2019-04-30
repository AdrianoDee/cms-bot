#!/bin/bash -ex
# This script will be us by jenkins job (https://cmssdt.cern.ch/jenkins/job/ib-any-integration)
# It will generate --sources flag for pkgtools/build.py script and move package to specific directory
# TODO - not all packages have matching repo name with project name
# TODO We should create a map in cmsdist for such pacakges
# ---
SCRIPTPATH="$( cd "$(dirname "$0")" ; /bin/pwd -P )"  # Absolute path to script
CMS_BOT_DIR=$(dirname ${SCRIPTPATH})  # To get CMS_BOT dir path
WORKSPACE=$(dirname ${CMS_BOT_DIR} )
CACHED=${WORKSPACE}/CACHED

PKG_REPO=$1       # Repo of external (ex. cms-sw/root)
PKG_NAME=$2       # Name of external (ex. root)
CMS_SW_TAG=$3     # CMS SW TAG found in config_map.py
ARCHITECTURE=$4           # Architecture (ex. slc7_amd64_gcc700)
BUILD_DIR="testBuildDir"  # Where pkgtools/cmsBuild builds software

SPEC_NAME=${PKG_NAME}
case ${PKG_REPO} in
  cms-data/*) SPEC_NAME="data-${PKG_NAME}" ;;
esac
# ---

# Checked if variables are passed
if [[ -z "$PKG_REPO" || -z "$PKG_NAME" || -z "$CMS_SW_TAG" ]]; then
    >&2 echo "empty parameters"
    >&2 echo "EXTERNAL_REPO: '${PKG_REPO}', PKG_NAME: '${PKG_NAME}', CMS_SW_TAG: '${CMS_SW_TAG}'"
    exit 1
fi

cd ${WORKSPACE}
FILTERED_CONF=$(${CMS_BOT_DIR}/common/get_config_map_line.sh "${CMS_SW_TAG}" "" "${ARCHITECTURE}" )
CMSDIST_BRANCH=$(echo ${FILTERED_CONF} | sed 's/^.*CMSDIST_TAG=//' | sed 's/;.*//' )
if [[ -z ${ARCHITECTURE} ]] ; then
  ARCHITECTURE=$(echo ${FILTERED_CONF} | sed 's/^.*SCRAM_ARCH=//' | sed 's/;.*//' )
fi
PKG_TOOL_BRANCH=$(echo ${FILTERED_CONF} | sed 's/^.*PKGTOOLS_TAG=//' | sed 's/;.*//' )
PKG_TOOL_VERSION=$(echo ${PKG_TOOL_BRANCH} | cut -d- -f 2)
# Check if PKG_TOOL_VERSION high enough
if [ ${PKG_TOOL_VERSION} -lt 32 ] ; then
    >&2 echo "ERROR: CMS_SW_TG ${CMS_SW_TAG} uses PKG_TOOL_BRANCH ${PKG_TOOL_BRANCH} which is lower then required to test externals."
    exit 1
fi
if ! [ -d "cmsdist" ]; then
    git clone --depth 1 -b ${CMSDIST_BRANCH} https://github.com/cms-sw/cmsdist.git
else
    # check if existing cmsdist repo points to correct branch
    pushd cmsdist
        ACTUAL_BRANCH=$(git branch | head -1 | sed 's|\*\s*||')
        if [ ${ACTUAL_BRANCH} != ${CMSDIST_BRANCH} ] ; then
            >&2 echo "Expected CMSDIST branch to be ${CMSDIST_BRANCH}, actual branch is ${ACTUAL_BRANCH} "
            exit 1
        fi
    popd
fi

if ! [ -d "pkgtools" ]; then
    git clone --depth 1 -b ${PKG_TOOL_BRANCH} https://github.com/cms-sw/pkgtools.git
fi

SOURCES=$(./pkgtools/cmsBuild -c cmsdist/ -a ${ARCHITECTURE} -i ${BUILD_DIR} -j 8 --sources build  ${SPEC_NAME} | \
                        grep -i "^${SPEC_NAME}:source" | grep github.com/.*/${PKG_NAME}\.git | tr '\n' '#' )

N=$(echo ${SOURCES} | tr '#' '\n' | grep -ci ':source' ) || true
echo "Number of sources: " ${N}
echo "Sources:"
echo ${SOURCES}

if [ ${N} -eq 0 ]; then
   >&2 echo "ERROR: External sources not found"
   exit 1
elif [ ${N} -eq 1 ]; then
   echo "One source found"
else
   >&2 echo  "ERROR: More then one external source is found"
   exit 1
fi

OUTPUT=$(echo ${SOURCES}  | sed 's/ .*//' | tr '#' '\n' )
SOURCE_NAME=$(echo ${OUTPUT} | sed 's/.*://' | sed 's/=.*//')
DIR_NAME=$(echo ${OUTPUT} | sed 's/.*=//')

# Move to other path
rm -rf ${PKG_NAME}/.git  # remove git metadata - we wont need it when packing.
if [ ${PKG_NAME} != ${DIR_NAME} ]; then
    mv ${PKG_NAME} ${DIR_NAME}
fi
echo "--source ${SPEC_NAME}:${SOURCE_NAME}=$(pwd)/${DIR_NAME}" >> get_source_flag_result.txt
