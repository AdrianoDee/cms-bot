#!/usr/bin/env python
from os.path import exists, join, basename
from sys import exit
from commands import getstatusoutput
from hashlib import sha256

def run_cmd (cmd, exit_on_error=True):
  err, out = getstatusoutput (cmd)
  if err and exit_on_error:
    print out
    exit (1)
  return out

class logwatch (object):
  def __init__ (self, service, log_dir="/var/log"):
    self.log_dir = join(log_dir,"logwatch_" + service)

  def process(self, logs, callback, **kwrds):
    if not logs: return True, 0
    info_file = join(self.log_dir, "info")
    if not exists ("%s/logs" % self.log_dir): run_cmd ("mkdir -p %s/logs" % self.log_dir)
    prev_lnum, prev_hash, count, data = -1, "", 0, []
    if exists(info_file):
      prev_hash,ln = run_cmd("head -1 %s" % info_file).strip().split(" ",1)
      prev_lnum = int(ln)
      if prev_lnum<1: prev_lnum=1
    for log in reversed(logs):
      service_log = join (self.log_dir, "logs", basename(log))
      run_cmd ("rsync -a %s %s" % (log, service_log))
      cur_hash = sha256(run_cmd("head -1 %s" % service_log)).hexdigest()
      data.insert(0,[log , service_log, 1, cur_hash, False])
      if (prev_lnum>0) and (cur_hash == prev_hash):
        data[0][2] = prev_lnum
        break
    data[-1][4] = True
    for item in data:
      lnum, service_log = item[2], item[1]
      get_lines_cmd = "tail -n +%s %s" % (str(lnum),  service_log)
      if lnum<=1: get_lines_cmd = "cat %s" % service_log
      print "Processing %s:%s" % (item[0], str(lnum))
      lnum -= 1
      for line in run_cmd (get_lines_cmd).split ("\n"):
        count += 1
        lnum += 1
        try: ok = callback(line, count, **kwrds)
        except: ok = False
        if not ok:
          if (prev_lnum!=lnum) or (prev_hash!=item[3]):
            run_cmd("echo '%s %s' >  %s" % (item[3], str(lnum),info_file))
          return status, count
      if (prev_lnum!=lnum) or (prev_hash!=item[3]):
        prev_lnum=-1
        cmd = "echo '%s %s' >  %s" % (item[3], str(lnum),info_file)
        if not item[4]: cmd = cmd + " && rm -f %s" % service_log
        run_cmd(cmd)
    return True, count

