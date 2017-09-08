#! /usr/bin/env python
from sys import exit, argv
from os import environ
from cmsutils import cmsRunProcessCount, doCmd
from logUpdater import LogUpdater

if (not environ.has_key("CMSSW_BASE")) or (not environ.has_key("SCRAM_ARCH")):
  print "ERROR: Unable to file the release environment, please make sure you have set the cmssw environment before calling this script"
  exit(1)

timeout=7200
try: timeout=int(argv[1])
except: timeout=7200
logger = LogUpdater(environ["CMSSW_BASE"])
ret = doCmd('cd %s; rm -rf addOnTests; timeout %s addOnTests.py -j %s 2>&1 >addOnTests.log' % (environ["CMSSW_BASE"], timeout,cmsRunProcessCount))
doCmd('cd '+environ["CMSSW_BASE"]+'/addOnTests/logs; zip -r addOnTests.zip *.log')
logger.updateAddOnTestsLogs()

