#!/usr/bin/env python

import os
import sys

if 1 == len(sys.argv):
	print(sys.argv[0] + " angular_dist_dir!")
	exit()

dir_to_patch = sys.argv[1]
print(dir_to_patch)

cmd = "sed -i 's/ type=\"module\"//g' %s/index.html" % (dir_to_patch)
# os.system(cmd)
print(cmd)

cmd = "sed -i 's/ nomodule defer//g' %s/index.html" % (dir_to_patch)
# os.system(cmd)
print(cmd)