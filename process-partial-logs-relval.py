#!/usr/bin/env python
import os, sys
from runPyRelValThread import PyRelValsThread

path=sys.argv[1]
newloc = os.path.dirname(path) + '/pyRelValMatrixLogs/run'
os.system('mkdir -p ' + newloc)
ProcessLogs = PyRelValsThread(1,path,"1of1",newloc)
print "Generating runall log file"
ProcessLogs.update_runall()
print "Generating relval time info"
ProcessLogs.update_wftime()
print "Parsing logs for workflows/steps"
