#! /usr/bin/python

import ConfigParser
import StringIO
import sys
import os

conf_file = "/tmp/conf"

if len(sys.argv) > 1:
    conf_file = sys.argv[1]

# print "conffile "+conf_file

if not os.path.isfile(conf_file):
    print "File " + conf_file + " not found"
    sys.exit(1)

# Class for adding a section into config file
class FakeSecHead(object):
    def __init__(self, fp):
        self.fp = fp
        self.sechead = '[a]\n'

    def readline(self):
        if self.sechead:
            try: return self.sechead
            finally: self.sechead = None
        else: return self.fp.readline()

cp = ConfigParser.ConfigParser()
cp.readfp(FakeSecHead(open(conf_file)))

# Options from config file will be stored in this dictionary
values = {} 

for section in cp.sections():
    for option in cp.options(section):
        values[option] = cp.get(section,option)
        
for v in values:
    print v+"="+values[v]

