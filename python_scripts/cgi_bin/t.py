#!/usr/bin/python

# check if file <name>.act is present if yes then run the command , save the output in <name>.act.out
# remove <name>.act

#import subprocess

#q = subprocess.check_output('/usr/bin/ls /var/tmp')
#  if ".act" in q:
#    print "Rar exists"

import os

mylist = os.listdir('/var/tmp')
item1=""

for i in mylist:
  #print i
  if ".act" in i:
    print "working: " + i
    #print i
    x = i.split(".act")
    item1=x[0]

    outfile= "/var/tmp/" + item1 + ".out"
    if os.path.exists(outfile):
      os.remove(outfile)
    stream = os.popen('date')
    output = stream.read()
    #print outfile
    f=open(outfile,"w+")
    f.write(output)
    f.close()
    #os.remove(i)

