#!/usr/bin/env python
#read yaml data file as a text file and comment anything given in filters.yaml
import re
import json
import yaml

file='test.yaml'

data={}
with open(file) as f:
  content = f.readlines()
  
  for x in content:
    #x = x.strip()
    #print x
    if x.startswith('"'):
      res=x
      #x = {} 
      data[res]={}

    if x.startswith('  "'):
      res_name=x
      data[res][res_name]=[]

    if x.startswith('    '):
      res_des=x
      data[res][res_name].append(res_des)
      
filters={}
file1='filters.yaml'
with open(file1) as f1:
  content = f1.readlines()
  
  for x in content:
    if x.startswith('"'):
      res=x
      #x = {} 
      filters[res]={}

    if x.startswith('  "'):
      res_name=x
      filters[res][res_name]=[]

#print(yaml.dump(data, indent = 2))
#print(json.dumps(data, indent = 2))
#print(json.dumps(filters, indent = 2))
print "Before"
for res in data:
  print res.rstrip()
  for res_name in data[res]:
    print res_name.rstrip()
    for res_des in data[res][res_name]:
      print res_des.rstrip()

for key in filters:
  if key in data.keys():
    res=key
    for key1 in filters[res]:
      if key1 in data[res].keys():
        res_name=key1
        #print res.strip() + " " + res_name.strip() + " Need disable"    
        new_res_name="#"+res_name
        #print new_res_name
        for i,res_des in enumerate(data[res][res_name]):
          #print res_des 
          new_res_des="#"+res_des
          #print new_res_des
          data[res][res_name][i]=new_res_des
        data[res][new_res_name]=data[res].pop(res_name)

#print(json.dumps(data, indent = 2))
print "After"
with open("test_new.yaml",'w') as f:
  for res in data:
    print res.rstrip()
    f.write(res)
    for res_name in data[res]:
      print res_name.rstrip()
      f.write(res_name)
      for res_des in data[res][res_name]:
        print res_des.rstrip()
        f.write(res_des)
f.close()


###########################################################

