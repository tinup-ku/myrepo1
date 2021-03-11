#!/usr/bin/python

# http://server-name/cgi-bin/cert.cgi?cert=cert_name
# Import modules for CGI handling
import cgi, cgitb
import os
import time
cgitb.enable()

#form to accept cert name
print "Content-type:text/html\r\n\r\n"
print "<html>"
print "<head>"
print "<title>Cert clean CGI </title>"
print "</head>"
print '<h1>Please enter a certname to remove</h1>'
print '<form action="cert.cgi" method="get">'
print 'Cert: <input type="text" name="cert">  <br />'
print '<input type="submit" value="Submit" />'
print '</form>'
print "</html>"

# Create instance of FieldStorage
form = cgi.FieldStorage()

# Get data from fields
cert = form.getvalue('cert')

# if cert name is found using url or form , execute rest. if not then exit
if cert:
  pass
else:
  exit()


#create file in /temp(perm 777) since cgi can't create file anywhere else
newfile="/temp/" + cert + ".act"
f=open(newfile,"w+")
f.write("test")
f.close()

#cert_clean script running thru cron will clean cert and drop cert.out file in /temp
#check for the file and display contents
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

print "<body>"
print "<h3>%s</h3>" % msg
#print "<h3>%s</h3>" % msg1
#print "<h3>%s</h3>" % msg2
for line in out:
  print line
  print "<br>"
print "</body>"
