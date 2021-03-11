#!/usr/bin/python
with open('file1.txt') as infile:
    f1 = infile.readlines()

with open('file2.txt') as infile:
    f2 = infile.readlines()

only_in_f1 = [i for i in f1 if i not in f2]
only_in_f2 = [i for i in f2 if i not in f1]

with open('file3.txt', 'w') as outfile:
    #if only_in_f1:
    #    outfile.write('Lines only in file 1:\n')
    #    for line in only_in_f1:
    #        outfile.write(line)

    if only_in_f2:
        #outfile.write('Lines only in file 2:\n')
        for line in only_in_f2:
            outfile.write(line)
