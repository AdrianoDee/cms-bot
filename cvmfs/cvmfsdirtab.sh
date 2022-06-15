#!/bin/bash
#Shared files
for cmsdir in "$@" ; do
  if [ $(ls ${CVMFS_DIR}/$cmsdir -d 2>/dev/null | wc -l) -eq 0 ] ; then continue ; fi
  echo "/${cmsdir}/share"
  for x in cms/data-L1Trigger-L1TMuon cms/data-GeneratorInterface-EvtGenInterface 'cms/data-MagneticField-Interpolation/*' ; do
    echo "/${cmsdir}/share/${x}"
  done

  #cmssw externals
  echo "/${cmsdir}/*_*_*/external/*"
  for x in blackhat boost cuda geant4 geant4-G4EMLOW herwigpp madgraph5amcatnlo py2-pippkgs py2-pippkgs_depscipy sherpa rivet; do
    echo "/${cmsdir}/*_*_*/external/${x}/*"
  done

  #Some special directories
  for x in cms lcg lcg/root ; do
    echo "/${cmsdir}/*_*_*/${x}"
  done

  #for cmssw releases
  for x in cmssw cmssw-patch ; do
    echo "/${cmsdir}/*_*_*/cms/${x}/CMSSW_*/src"
    echo "/${cmsdir}/*_*_*/cms/${x}/CMSSW_*"
  done
  if [[ "${cmsdir}" == "*week*" -a -d ${CVMFS_DIR}/$cmsdir/spack ]]; then
    echo ${cmsdir}"/spack/share"
    echo ${cmsdir}"/spack/share/data-l1trigger-l1tmuon"
    echo ${cmsdir}"/spack/share/data-generatorinterface-evtgeninterface"
    echo ${cmsdir}"/spack/share/data-magneticfield-interpolation/*"
    echo ${cmsdir}"/spack"
    # All platforms
    echo ${cmsdir}"/spack/*-*-*"
    # All compilers
    echo ${cmsdir}"/spack/*-*-*/*-*"
    # All packages
    echo ${cmsdir}"/spack/*-*-*/*-*/*"
    # All versions for select packages
    echo ${cmsdir}"/spack/*-*-*/*-*/blackhat/*"
    echo ${cmsdir}"/spack/*-*-*/*-*/boost/*"
    echo ${cmsdir}"/spack/*-*-*/*-*/cuda/*"
    echo ${cmsdir}"/spack/*-*-*/*-*/geant4/*"
    echo ${cmsdir}"/spack/*-*-*/*-*/g4emlow/*"
    echo ${cmsdir}"/spack/*-*-*/*-*/herwig7/*"
    echo ${cmsdir}"/spack/*-*-*/*-*/madgraph5amc/*"
    echo ${cmsdir}"/spack/*-*-*/*-*/sherpa/*"
    echo ${cmsdir}"/spack/*-*-*/*-*/rivet/*"
    echo ${cmsdir}"/spack/*-*-*/*-*/root/*"
    echo ${cmsdir}"/spack/*-*-*/*-*/cmssw/CMSSW_*/src"
    echo ${cmsdir}"/spack/*-*-*/*-*/cmssw/CMSSW_*"
    echo ${cmsdir}"/spack/*-*-*/*-*/cmssw-patch/CMSSW_*/src"
    echo ${cmsdir}"/spack/*-*-*/*-*/cmssw-patch/CMSSW_*"
  fi
done
