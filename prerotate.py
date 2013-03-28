#!/usr/bin/python
"""

Simple script to datestamp log files that haven't been stamped via logrotate.

"""
import datetime
import os
import re
import sys

try:
    log_path = sys.argv[1]
except IndexError:
    print "USAGE: prerotate.py <path>"
    quit()

extension = ".gz"
files = os.listdir(log_path)
for obj in files:
    if obj.endswith(extension):
        pattern = ".*[0-9]{4}[0-9]{2}[0-9]{2}\%s$" % extension
        reg = re.compile(pattern)
        if not reg.match(obj):
            (mode, ino, dev, nlink, uid, gid, size, atime,
             mtime, ctime) = os.stat(log_path + obj)
            datestamp = datetime.datetime.fromtimestamp(
                int(mtime)).strftime('%Y%m%d')
            fileparts = obj.split(".")
            parts_count = len(fileparts)
            filename = fileparts[0]
            first_extension = fileparts[1]
            if parts_count == 3:
                new_name = filename + '-' + datestamp + extension
            elif parts_count == 4:
                new_name = filename + '.' + \
                    first_extension + '-' + datestamp + extension
            print "Renaming %s to %s" % (log_path + obj, log_path + new_name)
            os.rename(log_path + obj, log_path + new_name)
