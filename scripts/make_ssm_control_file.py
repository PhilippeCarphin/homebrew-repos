import datetime
import socket
import os
import pwd
import argparse
import json
import sys

p = argparse.ArgumentParser()
p.add_argument("--description", "-d", required=True, help="Set the \"description\": part of the control file")
p.add_argument("--version", "-v", required=True, help="Set the \"version\": part of the control file")
p.add_argument("--name", "-n", required=True, help="Set the \"name\": part of the control file")
p.add_argument("--summary", "-s", required=True, help="Set the \"summary\": part of the control file")
args = p.parse_args()
user = pwd.getpwuid(os.getuid())
uname = os.uname()
control_dict = {
        "name": args.name,
        "version": args.version,
        "platform": "all",
        "summary": args.summary,
        "maintainer": user.pw_gecos,
        "description": args.description,
         "x-build-date": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
         "x-build-platform": uname.machine,
         "x-build-host": socket.getfqdn(),
         "x-build-user": user.pw_name,
         "x-build-uname": f"('{uname.sysname}', '{uname.nodename}', '{uname.release}', '{uname.version}', '{uname.machine}')"
}


json.dump(control_dict, sys.stdout, indent=4)
