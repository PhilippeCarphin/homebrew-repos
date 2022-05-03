#!/usr/bin/env python3

import sys
import yaml
import argparse
import os

class RepoAdderError(Exception):
    pass

def get_args():
    p = argparse.ArgumentParser(description="Add a repo to the repos.yml config file")
    p.add_argument("-F", help="Specify alternate file to ~/.config/repos.yml")
    p.add_argument("repo", help="Specify the repository, defaults to $PWD", nargs='?')
    p.add_argument("--name", help="Specify name for repo in config file")

    args = p.parse_args()

    if not args.repo:
        args.repo = os.environ['PWD']

    if not args.name:
        args.name = os.path.basename(args.repo)

    return args

def main(args):
    repo_file = args.F if args.F else os.path.expanduser("~/.config/repos.yml")
    with open(repo_file) as y:
        d = yaml.safe_load(y)
    if not os.path.isdir(os.path.join(args.repo, '.git')):
        raise RepoAdderError(f"It seems repo '{args.repo}' is not a git repository, skipping ...")
    if args.name in d['repos']:
        raise RepoAdderError(f"Repo '{args.repo}' is already in '{repo_file}' under name '{args.name}' skipping ...")
    d['repos'][args.name] = {"path": args.repo}
    print(f"{sys.argv[0]}: \033[1;35mINFO\033[0m: Added '{args.repo}' to '{repo_file}' under name '{args.name}'")
    with open(repo_file, 'w') as y:
        yaml.dump(d,y)

if __name__ == "__main__":
    try:
        sys.exit(main(get_args()))
    except RepoAdderError as e:
        print(f"{sys.argv[0]}: \033[1;31mERROR\033[0m: {e}")
