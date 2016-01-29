#!/usr/bin/env python
import re
RELVAL_KEYS = {"dropNonMTSafe":{}, 
               "customiseWithTimeMemorySummary":{}, 
               "PREFIX":{},
               "JOB_REPORT":{},
               "USE_INPUT":{},
               "THREADED":{},
               "DAS_OPTION":{},
               "SLHC_WORKFLOWS":{},
              }

RELVAL_KEYS["dropNonMTSafe"]["_(THREADED|ROOT6)_"]  = "--customise FWCore/Concurrency/dropNonMTSafe.dropNonMTSafe"
RELVAL_KEYS["customiseWithTimeMemorySummary"][".+"] = "--customise Validation/Performance/TimeMemorySummary.customiseWithTimeMemorySummary"
RELVAL_KEYS["PREFIX"]["CMSSW_8_.+"]         = "--prefix 'timeout --signal SIGTERM 7200 '"
RELVAL_KEYS["PREFIX"]["^(?!CMSSW_8_).+"]    = "--prefix 'timeout --signal SIGSEGV 7200 '"
RELVAL_KEYS["JOB_REPORT"][".+"]             = "--job-reports"
RELVAL_KEYS["USE_INPUT"][".+"]              = "--useInput all"
RELVAL_KEYS["THREADED"]["_THREADED_"]       = "-t 4"
RELVAL_KEYS["DAS_OPTION"][".+"]             = "--das-options '--cache @DAS_FILE@'"
RELVAL_KEYS["SLHC_WORKFLOWS"]["_SLHCDEV_"]  = "-w upgrade -l 10000,10061,10200,10261,10800,10861,12200,12261,14400,14461,12600,12661,14000,14061,12800,12861,13000,13061,13800,13861"
RELVAL_KEYS["SLHC_WORKFLOWS"]["_SLHC_"]     = "-w upgrade -l 10000,10061,10200,10261,12200,12261,14400,14461,12600,12661,14000,14061,12800,12861,13000,13061,13800,13861"

RELVAL_ARGS = []
RELVAL_ARGS.append({})
#For SLHC releases
RELVAL_ARGS[len(RELVAL_ARGS)-1]["_SLHC(DEV|)_"]="""
  @USE_INPUT@
  @SLHC_WORKFLOWS@
"""
RELVAL_ARGS[len(RELVAL_ARGS)-1]["CMSSW_4_2_"]=""

RELVAL_ARGS.append({})
#For rleease cycles >= 7
RELVAL_ARGS[len(RELVAL_ARGS)-1]["CMSSW_([1-9][0-9]|[7-9])_"]="""
  @USE_INPUT@
  @JOB_REPORT@
  --command "
    @customiseWithTimeMemorySummary@
    @dropNonMTSafe@
    @PREFIX@
  "
  @THREADED@
  @DAS_OPTION@
"""

RELVAL_ARGS.append({})
#For all other releases
RELVAL_ARGS[len(RELVAL_ARGS)-1][".+"]="""
  @USE_INPUT@
"""

def GetMatrixOptions(release, arch, dasfile=None):
  rel_arch = release+":"+arch
  for exp in RELVAL_KEYS["DAS_OPTION"]:
    if not dasfile:
      RELVAL_KEYS["DAS_OPTION"][exp]=''
    else:
      RELVAL_KEYS["DAS_OPTION"][exp]=RELVAL_KEYS["DAS_OPTION"][exp].replace("@DAS_FILE@",dasfile)

  cmd = ""
  for rel in RELVAL_ARGS:
    for exp in rel:
      if re.search(exp,rel_arch):
        cmd = rel[exp].replace("\n"," ")
        break
    if cmd: break
  m=re.search("(@([a-zA-Z_]+)@)",cmd)
  while m:
    key = m.group(2)
    val = ""
    if RELVAL_KEYS.has_key(key):
      for exp in RELVAL_KEYS[key]:
        if re.search(exp,rel_arch): val = val + RELVAL_KEYS[key][exp] + " "
    cmd = cmd.replace(m.group(1), val)
    m=re.search("(@([a-zA-Z_]+)@)",cmd)
  
  return re.sub("\s+"," ",cmd)

