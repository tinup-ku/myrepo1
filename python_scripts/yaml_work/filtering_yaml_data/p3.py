#!/usr/bin/python
# read yaml file and print it back 
import yaml
import io
import pprint

# Write YAML file
#with io.open('data.yaml', 'w', encoding='utf8') as outfile:
#    yaml.dump(data, outfile, default_flow_style=False, allow_unicode=True)

# Read YAML file
with open("test.yaml", 'r') as stream:
    dy = yaml.safe_load(stream)

print "printing dict:"
print(dy)

#pp = pprint.PrettyPrinter(indent=2)
#pp.pprint(dy)
#print yaml.dump(dy)

#print dy["packages"]
#
for i in dy:
  print "\"" + i + "\"" + ":"
  for x in dy[i]:
    print "  " + "\"" + x + "\"" + ":"
    for y in dy[i][x]:
      if (y == 'ensure'):
        val = "\"" + (str(dy[i][x][y])).lower() +"\""
      else:
        val = (str(dy[i][x][y])).lower()

      print "    " + y + ": " + val 




#    if (x == 'httpd'):
#      print "update the httpd"
#      for y in dy['packages']['httpd']:
#        print y

