#! /usr/bin/env python
from sys import exit
from optparse import OptionParser
from os import environ
from runPyRelValThread import PyRelValsThread
from RelValArgs import GetMatrixOptions, isThreaded
from logUpdater import LogUpdater
from cmsutils import cmsRunProcessCount, MachineMemoryGB, doCmd
from cmssw_known_errors import KNOWN_ERRORS

if __name__ == "__main__":
  parser = OptionParser(usage="%prog -i|--id <jobid> -l|--list <list of workflows>")
  parser.add_option("-i", "--id",   dest="jobid", help="Job Id e.g. 1of3", default="1of1")
  parser.add_option("-l", "--list", dest="workflow", help="List of workflows to run e.g. 1.0,2.0,3.0", type=str, default=None)
  parser.add_option("-f", "--force",dest="force", help="Force running of workflows without checking the server for previous run", action="store_true", default=False)
  opts, args = parser.parse_args()

  if len(args) > 0: parser.error("Too many/few arguments")
  if not opts.workflow: parser.error("Missing -l|--list <workflows> argument.")
  if (not environ.has_key("CMSSW_VERSION")) or (not environ.has_key("CMSSW_BASE")) or (not environ.has_key("SCRAM_ARCH")):
    print "ERROR: Unable to file the release environment, please make sure you have set the cmssw environment before calling this script"
    exit(1)

  thrds = cmsRunProcessCount
  cmssw_ver = environ["CMSSW_VERSION"]
  arch = environ["SCRAM_ARCH"]
  if isThreaded(cmssw_ver,arch):
    print "Threaded IB Found"
    thrds=int(MachineMemoryGB/4.5)
    if thrds==0: thrds=1
  elif "fc24_ppc64le_" in arch:
    print "FC22 IB Found"
    thrds=int(MachineMemoryGB/4)
  elif "fc24_ppc64le_" in arch:
    print "CentOS 7.2 + PPC64LE Found"
    thrds=int(MachineMemoryGB/3)
  else:
    print "Normal IB Found"
  if thrds>cmsRunProcessCount: thrds=cmsRunProcessCount
  known_errs = {}
  for rel in KNOWN_ERRORS["relvals"]:
    if cmssw_ver.startswith(rel) and (arch in KNOWN_ERRORS["relvals"][rel]):
      known_errs = KNOWN_ERRORS["relvals"][rel][arch]
      break
  matrix = PyRelValsThread(thrds, environ["CMSSW_BASE"]+"/pyRelval", opts.jobid)
  matrix.setArgs(GetMatrixOptions(cmssw_ver,arch))
  matrix.run_workflows(opts.workflow.split(","),LogUpdater(environ["CMSSW_BASE"]),opts.force,known_errors=known_errs)

