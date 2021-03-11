#!/usr/bin/python
# using ruamel to process yaml file , using ruamel will preserve the order of data file which it read 
#import yaml
#from ruamel import yaml
import ruamel.yaml
import io
import pprint

yaml = ruamel.yaml.YAML()
yaml.indent(mapping=2)
yaml.preserve_quotes = True


# Read YAML file
with open("test.yaml", 'r') as stream:
    dy = yaml.load(stream)

print "printing dict:"
print(dy)


print dy["packages"]

for i in dy:
  print "\"" + i + "\"" + ":"
  for x in dy[i]:
    if (x == 'httpd'):
      print "#  " + "\"" + x + "\"" + ":"
      for y in dy[i][x]:
        if (y == 'ensure'):
          val = "\"" + (str(dy[i][x][y])).lower() +"\""
        else:
          val = (str(dy[i][x][y])).lower()
  
        print "#    " + y + ": " + val 
    else:
      print "  " + "\"" + x + "\"" + ":"
      for y in dy[i][x]:
        if (y == 'ensure'):
          val = "\"" + (str(dy[i][x][y])).lower() +"\""
        else:
          val = (str(dy[i][x][y])).lower()
  
        print "    " + y + ": " + val 

