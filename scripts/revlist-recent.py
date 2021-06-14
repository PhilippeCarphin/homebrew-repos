#!/usr/bin/env python3

import subprocess
import datetime
from pprint import pprint

class Repo:
    def __init__(self, repo_dir):
        self.repo_dir = repo_dir
    def test(self):
        return list(get_recent_commits(self.repo_dir, "test-branch", 8))



def get_recent_commits(repo_dir, branch, days):
    """ Create a list of commits made on a branch between now and a number of
    days in the past.

    Implementation details:

    We use 'git rev-list {branch} --after={date} --pretty=format:{format} where date is
    today's date minus the prescribed number of days and {format} makes the
    output easy to parse.

    The format is "{Commit Hash} {Unix timestamp} {Commit message}"
    """
    now = datetime.date.today()
    yesterday = now - datetime.timedelta(days=1)
    before_yesterday = now - datetime.timedelta(days=1+days)

    cmd = 'cd {} && git rev-list {} --after="{}" --pretty=format:"%h %at %s"'.format(
            repo_dir, branch, before_yesterday.strftime("%Y-%m-%d 12:00"))
    result = subprocess.run(
        cmd,
        shell=True,
        universal_newlines=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=True,
    )
    for l in result.stdout.splitlines():
        if l.startswith("commit"):
            continue
        words = l.split()
        yield {
            "date": datetime.datetime.fromtimestamp(int(words[1])),
            "hash": words[0],
            "message": ' '.join(words[2:]),
        }
if __name__ == "__main__":
    r = Repo("/Users/pcarphin/Documents/GitHub/repos")
    pprint(r.test())
