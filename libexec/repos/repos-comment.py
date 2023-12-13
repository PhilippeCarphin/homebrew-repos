#!/usr/bin/env python3
import yaml
import os
import sys
import argparse

def get_args():
    p = argparse.ArgumentParser(description="Set the ignore flag of a repo to true")
    p.add_argument("-F", help="Specify alternate file to ~/.config/repos.yml")
    p.add_argument("--name", help="Specify name for repo in config file.  Defaults to basename(os.getcwd())")
    p.add_argument("--get", help="Get comment for repo", action='store_true')
    p.add_argument("--set", help="Set comment for repo")
    args = p.parse_args()
    return args

def main():
    args = get_args()
    repo_file = args.F if args.F else os.path.expanduser("~/.config/repos.yml")

    if args.name is None:
        print(f"Using basename(PWD) as repo name to commment")
        args.name = os.path.basename(os.getcwd())

    with open(repo_file) as f:
        database = yaml.safe_load(f)

    if args.name not in database['repos'] :
        print(f"No repo with name '{args.name}' in repo file '{repo_file}'")
        return 1

    repo = database['repos'][args.name]

    if args.set:
        if 'comment' in repo:
            print(f"Replacing comment '{repo['comment']}'")
        repo['comment'] = args.set
        with open(repo_file, 'w') as f:
            yaml.dump(database, f)
    elif args.get:
        if 'comment' in repo:
            print(repo['comment'])
        else:
            print("The repo '{args.name}' has no comment")

sys.exit(main())


