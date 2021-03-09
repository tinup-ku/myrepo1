#!/usr/bin/python

# http://myserver/cgi-bin/cert.cgi?cert=cert_name
# Import modules for CGI handling
import cgi, cgitb
import os
import time

# Create instance of FieldStorage
form = cgi.FieldStorage()

# Get data from fields
cert = form.getvalue('cert')
#last_name  = form.getvalue('last_name')

#create file in /temp(perm 777) since cgi can't create file anywhere else
newfile="/temp/" + cert + ".act"
f=open(newfile,"w+")
f.write("test")
f.close()

if os.path.exists(newfile):
  msg="Working on cert: " + cert
else:
  msg="Failed to work on: " + cert

outfile= "/temp/" + cert + ".out"
found="no"
line1=""
msg1=""
n=0
out=[]

while n < 10 :
   if os.path.exists(outfile):
     cont = open(outfile, "r")
     msg1="Found outfile:"
     found="yes"
     for line in cont:
       out.append(line)
     os.remove(outfile)
     break
   else:
     time.sleep(1)
     n=n+1
     #continue

if found == "no":
  msg1="Cert clean not successful..."

#os.remove(newfile)

print "Content-type:text/html\r\n\r\n"
print "<html>"
print "<head>"
print "<title>Cert clean CGI </title>"
print "</head>"
print "<body>"
print "<h3>%s</h3>" % msg
#print "<h3>%s</h3>" % msg1
#print "<h3>%s</h3>" % msg2
for line in out:
  print line
  print "<be>"
print "</body>"
print "</html>"


