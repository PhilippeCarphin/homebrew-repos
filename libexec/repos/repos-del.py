#!/usr/bin/env python3
import sys
import yaml
import argparse
import os
import subprocess
import shutil
import _repos_logging

logger = _repos_logging.logger

DESCRIPTION = """
Delete a repo from disc and from the repos config file.  NOTE: Although this
tool performs some checks to prevent work from being lost, only use it if you
would be willing to rm -rf the repo."""

def get_args():
    p = argparse.ArgumentParser(description=DESCRIPTION)
    p.add_argument("-F", help="Specify alternate file to ~/.config/repos.yml")
    p.add_argument("repo", help="Specify the repository, defaults to $PWD", nargs='?')
    p.add_argument("--name", help="Specify name for repo in config file")

    args = p.parse_args()

    if not args.repo:
        args.repo = os.environ['PWD']

    if not args.name:
        args.name = os.path.basename(args.repo)

    return args

def main():
    args = get_args()
    repo_file = args.F if args.F else os.path.expanduser("~/.config/repos.yml")
    with open(repo_file) as y:
        d = yaml.safe_load(y)

    repo = d['repos'].get(args.name)
    if repo is None:
        logger.error(f"No such repo '{args.name}'")
        return 1

    path = repo['path']
    logger.info(f"Repo '{args.name}' at path '{path}'")

    try:
        if not can_erase(repo):
            return 1
        resp = input("Are you sure you want to delete this repo? [yes|no] > ")
        if resp.lower() != 'yes':
            return 0
        shutil.rmtree(path)
        logger.info(f"Repo '{path}' deleted")
    except FileNotFoundError as e:
        logger.info(f"Repo not found: {e}")

    del d['repos'][args.name]

    with open(repo_file, 'w') as y:
        yaml.dump(d,y)

    logger.info(f"Repo removed from repo_file '{repo_file}'")

def can_erase(repo):
    result = True

    status = subprocess.run('git status',
        shell=True,
        cwd=repo['path'],
        check=True,
        stdout=subprocess.PIPE,
        universal_newlines=True
    ).stdout

    if 'Untracked files' in status:
        logger.error(f"There are untracked files, please cleanup first")
        result = False

    if 'Your branch is behind' in status:
        logger.error(f"Current branch is behind its remote counterpart, push first")
        result = False

    if 'Changes not staged' in status:
        logger.error(f"There are unstaged changes, make a commit first")
        result = False

    if 'Changes to be committed' in status:
        logger.error(f"There are staged changes, make a commit first")
        result = False

    return result

sys.exit(main())



