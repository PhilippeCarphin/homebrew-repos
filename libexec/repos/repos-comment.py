#!/usr/bin/env python3
import yaml
import os
import sys
import argparse

def get_args():
    p = argparse.ArgumentParser(description="Set the ignore flag of a repo to true")
    p.add_argument("-F", help="Specify alternate file to ~/.config/repos.yml")
    p.add_argument("--name", help="Specify name for repo in config file.  Defaults to basename(os.getcwd())")
    action = p.add_mutually_exclusive_group()
    action.add_argument("--get", help="Get comment for repo", action='store_true')
    action.add_argument("--set", help="Set comment for repo", metavar='COMMENT')
    action.add_argument("--clear", help="Remove comment from repo", action='store_true')
    args = p.parse_args()
    return args

def main():
    args = get_args()
    repo_file = args.F if args.F else os.path.expanduser("~/.config/repos.yml")

    if args.name is None:
        print(f"Using basename(PWD) as repo name to commment", file=sys.stderr)
        args.name = os.path.basename(os.getcwd())

    with open(repo_file) as f:
        database = yaml.safe_load(f)

    if args.name not in database['repos'] :
        print(f"No repo with name '{args.name}' in repo file '{repo_file}'", file=sys.stderr)
        return 1

    repos = database['repos']
    try:
        repo = repos[args.name]
    except KeyError as e:
        print(f"Repo '${args.name}' not found in repos section of repo_file '{repo_file}'", file=sys.stderr)
        return 1

    if args.set or args.clear:
        if args.set == "":
            print(f"Use --del to remove comments", file=sys.stderr)
            return 1
        if args.set:
            if 'comment' in repo:
                print(f"Replacing previous comment '{repo['comment']}'", file=sys.stderr)
            print(f"Setting comment to '{args.set}'", file=sys.stderr)
            repo['comment'] = args.set
        elif args.clear:
            if 'comment'in repo:
                print(f"Removing comment '{repo['comment']}'", file=sys.stderr)
                del repo['comment']
        with open(repo_file, 'w') as f:
            yaml.dump(database, f)
    elif args.get:
        if 'comment' in repo:
            print(repo['comment'])
        else:
            print("The repo '{args.name}' has no comment", file=sys.stderr)
            return 1

sys.exit(main())


