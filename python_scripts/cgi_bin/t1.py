#!/usr/bin/python

# create a file , run a loop to wait if a file.out file is created by another process
# if file.out is created then exit otherwise wait in loop
# remove <name>.act

import os
import time

first_name1="my"
newfile="/var/tmp/" + first_name1 + ".act"
f=open(newfile,"w+")
f.write("test")
f.close()

execfile("t.py")

outfile= "/var/tmp/" + first_name1 + ".out"
n=0
while n < 10 :
   if os.path.exists(outfile):
     cont = open(outfile, "r")
     print "Found outfile:"
     for line in cont:
       print(line)
     os.remove(outfile)
     break
   else:
     time.sleep(1)
     n=n+1
     #continue

os.remove(newfile)

