import os
import sys
import datetime
import subprocess

def main():
    import pprint

    repo_dir = os.getcwd()
    #pprint.pprint(get_commits(repo_dir))
    repo = Repo(repo_dir)

    now = datetime.datetime.now()
    before = now + datetime.timedelta(days=-2)
    selected_commits = list(repo.commits_between_dates(before, now))
    selected_commits = sorted(selected_commits, key=lambda c: c["date"])
    pprint.pprint(selected_commits)

class Repo:
    def __init__(self, repo_dir):
        self.repo_dir = repo_dir
        self.commits = list(get_commits_gen(repo_dir))

    def commits_between_dates(self, begin, end):
        for c in self.commits:
            date = c["date"]
            if begin <= date and date <= end:
                yield c


def get_commits_gen(repo_dir):
    result = subprocess.run(
        f'cd {repo_dir} && git log --date=unix --pretty=format:"%ad %H %s"',
        shell=True, universal_newlines=True, stdout=subprocess.PIPE
    )
    for l in result.stdout.splitlines():
        words = l.split()
        yield {
            "date": datetime.datetime.fromtimestamp(int(words[0])),
            "hash": words[1],
            "message": ' '.join(words[2:]),
        }

if __name__ == "__main__":
    sys.exit(main())



