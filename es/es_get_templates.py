#!/usr/bin/python
from os.path import dirname, basename, abspath, join
import sys

cmsbot_dir=None
if __file__: cmsbot_dir=dirname(dirname(abspath(__file__)))
else: cmsbot_dir=dirname(dirname(abspath(argv[0])))
sys.path.insert(0,cmsbot_dir)

import json
from commands import getstatusoutput as runcmd
from es_utils import get_template

tmpl = json.loads(get_template())
if 'proxy-error' in tmpl:
  print "Error: ",tmpl['proxy-error']
  sys.exit(1)

tmpl_dir="%s/es/templates" % cmsbot_dir
runcmd("mkdir -p %s" % tmpl_dir)
for t in tmpl:
  if not t.startswith("cmssdt-"): continue
  tfile = join(tmpl_dir,t+".json")
  print "Saving: ",tfile
  ref = open(tfile,"w")
  if ref:
    json.dump(tmpl[t],ref,indent=2, sort_keys=True, separators=(',',': '))
    ref.close()
