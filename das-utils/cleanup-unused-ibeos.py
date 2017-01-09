#!/usr/bin/env python
import json
from time import time
from sys import argv, exit
from os.path import dirname, abspath
from commands import getstatusoutput as run_cmd
script_path = abspath(dirname(argv[0]))
eos_cmd = "EOS_MGM_URL=root://eoscms.cern.ch /usr/bin/eos"
eos_base = "/eos/cms/store/user/cmsbuild"
unused_days_threshold = 28
try:days=int(argv[1])
except: days=10
if days<10: days=10
e , o = run_cmd("PYTHONPATH=%s/.. %s/ib-datasets.py --days %s" % (script_path, script_path, days))
if e:
  print o
  exit(1)

jdata = json.loads(o)
used = {}
for o in jdata[0]['hits']['hits']:
  used[o['_source']['lfn']]=1

e, o = run_cmd("%s find -f %s" % (eos_cmd, eos_base))
if e:
  print o
  exit(1)

total = 0
active = 0
unused = []
all_files = []
for l in o.split("\n"):
  l = l.replace(eos_base,"")
  all_files.append(l)
  if not l.endswith(".root"): continue
  total += 1
  if l in used:
    active += 1
    continue
  unused.append(l)

print "Total:",total
print "Active:",active
print "Unused:",len(unused)
if active == 0:
  print "No active file found. May be something went wrong"
  exit(1)

print "Renaming unused files"
for l in unused:
  if not l in all_files: continue
  pfn = "%s/%s" % (eos_base, l)
  e, o = run_cmd("%s stat -f %s" % (eos_cmd, pfn))
  if e:
    print o
    continue
  e, o = run_cmd("%s file rename %s %s.unused" % (eos_cmd, pfn, pfn))
  if e:
    print o
  else:
    print "Renamed: ",l
    run_cmd("%s file touch %s.unused" % (eos_cmd, pfn))

for unused_file in all_files:
  if not unused_file.endswith(".unused"): continue
  unused_file = "%s/%s" % (eos_base, unused_file)
  e, o = run_cmd("%s fileinfo %s | grep 'Modify:' | sed 's|.* Timestamp: ||'" % (eos_cmd, unused_file))
  if e or (o == ""):
    print o
    continue
  unused_days = int((time()-float(o))/86400)
  if unused_days<unused_days_threshold: continue
  print "Removing %s: %s days" % (unused_file, unused_days)
  run_cmd("%s rm %s" % (eos_cmd, unused_file))

