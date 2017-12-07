#!/usr/bin/env python
from optparse import OptionParser
import urllib2, urllib
from json import dumps

def process(opts):
  xparam = []
  for param in opts.params:
    p,v=param.split("=",1)
    xparam.append({"name":p,"value":v})
  data = {"json":dumps({"parameter":xparam}),"Submit": "Build"}
  try:
    url = opts.server+'/job/'+opts.job+'/build'
    data=urllib.urlencode(data)
    req = urllib2.Request(url=url,data=data,headers={"ADFS_LOGIN" : opts.user})
    content = urllib2.urlopen(req).read()
  except Exception as e:
    print "Unable to start jenkins job:",e

if __name__ == "__main__":
  parser = OptionParser(usage="%prog")
  parser.add_option("-j", "--job",        dest="job",        help="Jenkins jobs to trigger", default=None)
  parser.add_option("-s", "--server",     dest="server",     help="Jenkins server URL e.g. https://cmssdt.cern.ch/cms-jenkins", default=None)
  parser.add_option("-u", "--user",       dest="user",       help="Jenkins user name to trigger the job", default="cmssdt")
  parser.add_option('-p', '--parameter',  dest='params',     help="Job parameter e.g. -p Param=Value. One can use this multiple times.",
                    action="append", type="string", metavar="PARAMETERS")
  opts, args = parser.parse_args()

  if (not opts.job) or (not opts.server): parser.error("Missing job/server parameter.")
  process(opts)
