#!/usr/bin/python

# Run this script in cron every minute ; it exit if running more than once
# check if file <name>.act is present if yes then clean cert , save the output in <name>.out
# remove <name>.act

import os
import subprocess
import time

# check if already running /usr/bin/python ./cert_clean.py  exit if it is
cmd = ['ps -ef | grep cert_clean | grep -v grep | wc -l']
process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
p_out, p_err=process.communicate()

if int(p_out) >= 2 :
  print("Running Already..exiting")
  exit()

# looping below
while True:

  workdir="/temp"
  #remove files older then 59 minutes
  os.system('find /temp -mmin +59 -type f -exec rm -fv {} \;')
  mylist = os.listdir(workdir)
  item1=""

  for i in mylist:
    #print i
    if ".act" in i:
      print "working: " + i
      #print i
      x = i.split(".act")
      item1=x[0]

      outfile= workdir + "/" + item1 + ".out"
      if os.path.exists(outfile):
        os.remove(outfile)
      cmd="/usr/bin/ssh -q puppet_server_name puppet cert clean " + item1
      proc = subprocess.Popen(cmd.split(), stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
      output = proc.stdout.read()

      f=open(outfile,"w+")
      f.write(output)
      f.close()
      cmd1="chmod 777 " + outfile
      os.system(cmd1)
      act_file=workdir + "/" + i
      os.remove(act_file)
      time.sleep(2)

