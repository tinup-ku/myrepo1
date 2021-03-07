#!/usr/bin/python

#  use like: http://192.168.4.51/cgi-bin/name_get_py.cgi?first_name=PUNIT&last_name=KM
# Import modules for CGI handling 
import cgi, cgitb 
import os
stream = os.popen('uname -a')
output = stream.read()

# Create instance of FieldStorage 
form = cgi.FieldStorage() 

# Get data from fields
first_name = form.getvalue('first_name')
last_name  = form.getvalue('last_name')

print "Content-type:text/html\r\n\r\n"
print "<html>"
print "<head>"
print "<title>Hello - Second CGI Program</title>"
print "</head>"
print "<body>"
print "<h2>Hello %s %s</h2>" % (first_name, last_name)
print output
print "</body>"
print "</html>"

