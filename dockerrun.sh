function dockerrun()
{
  if [ -z "${CONTAINER_TYPE}" ] ; then
    CONTAINER_TYPE=docker
    [ "$USE_SINGULARITY" = "true" ] && CONTAINER_TYPE=singularity
    if [ -z "${IMAGE_BASE}" ] ; then IMAGE_BASE="/cvmfs/cms-ib.cern.ch/docker" ; fi
    if [ -z "${PROOTDIR}" ]   ; then PROOTDIR="/cvmfs/cms-ib.cern.ch/proot" ; fi
    if [ -z "${THISDIR}" ]    ; then THISDIR=$(/bin/pwd -P) ; fi
    if [ -z "${WORKDIR}" ]    ; then WORKDIR=$(/bin/pwd -P) ; fi
    arch=$(echo $SCRAM_ARCH | cut -d_ -f2)
    os=$(echo $SCRAM_ARCH | cut -d_ -f1 | sed 's|slc7|cc7|')
    IMG="cmssw/${os}:${arch}"
    if [ "${arch}" != "amd64" ] ; then
      CONTAINER_TYPE="qemu"
      QEMU_ARGS="$PROOTDIR/qemu-${arch}"
      if [ "${arch}" = "aarch64" ] ; then
        QEMU_ARGS="${QEMU_ARGS} -cpu cortex-a57"
      elif [ "${arch}" = "ppc64le" ] ; then
        QEMU_ARGS="${QEMU_ARGS} -cpu POWER8"
      fi
    fi
  fi
  case $CONTAINER_TYPE in
    docker)
      docker pull ${IMG}
      DOC_ARG="run --net=host -u $(id -u):$(id -g) --rm -t"
      DOC_ARG="${DOC_ARG} -v ${THISDIR}:${THISDIR} -v /tmp:/tmp -v /cvmfs:/cvmfs -v ${WORKDIR}:${WORKDIR}"
      ARGS="cd $THISDIR; for o in n s u ; do val=\"-\$o \$(ulimit -H -\$o) \${val}\"; done; ulimit \${val}; ulimit -n -s -u >/dev/null 2>&1; $@"
      docker $DOC_ARG ${IMG} sh -c "$ARGS"
      ;;
    singularity)
      UNPACK_IMG="${IMAGE_BASE}/${IMG}"
      ARGS="cd $THISDIR; for o in n s u ; do val=\"-\$o \$(ulimit -H -\$o) \${val}\"; done; ulimit \${val}; ulimit -n -s -u >/dev/null 2>&1; $@"
      singularity -s exec -B /tmp -B /cvmfs -B ${THISDIR}:${THISDIR} -B ${WORKDIR}:${WORKDIR} ${UNPACK_IMG} sh -c "$ARGS"
      ;;
    qemu)
      ls ${IMAGE_BASE} >/dev/null 2>&1
      ARGS="cd ${THISDIR}; $@"
      $PROOTDIR/proot -R ${IMAGE_BASE}/${IMG} -b /tmp:tmp -b /build:/build -b /cvmfs:/cvmfs -w ${THISDIR} -q "${QEMU_ARGS}" sh -c "${ARGS}"
      ;;
    *) eval $@;;
  esac
}
