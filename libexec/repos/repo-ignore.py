#!/usr/bin/env python3
import yaml
import os
import sys
import argparse

def get_args():
    p = argparse.ArgumentParser(description="Set the ignore flag of a repo to true")
    p.add_argument("-F", help="Specify alternate file to ~/.config/repos.yml")
    p.add_argument("--name", help="Specify name for repo in config file.  Defaults to basename(os.getcwd())")
    p.add_argument("--unignore", help="Unignore the repo", action='store_true')
    args = p.parse_args()
    return args

def main():
    args = get_args()
    repo_file = args.F if args.F else os.path.expanduser("~/.config/repos.yml")

    if args.name is None:
        print(f"Using basename(PWD) as repo name to ignore")
        args.name = os.path.basename(os.getcwd())

    with open(repo_file) as f:
        database = yaml.load(f)

    if args.name not in database['repos'] :
        print(f"No repo with name '{args.name}' in repo file '{repo_file}'")
        return 1

    repo = database['repos'][args.name]
    if args.unignore:
        if 'ignore' in repo:
            del repo['ignore']
    else:
        if 'ignore' in repo and repo['ignore']:
            print(f"Repo is already ignored")
        else:
            print(f"Adding 'ignore: true' to repo '{args.name}'")
            repo['ignore'] = True


    with open(repo_file, 'w') as f:
        yaml.dump(database, f)

sys.exit(main())


