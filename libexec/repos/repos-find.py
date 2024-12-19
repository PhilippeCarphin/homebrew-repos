#!/usr/bin/env python3
import os
import yaml
import argparse
import pprint
import sys
import re
import _repos_logging
import logging

logger = _repos_logging.logger

def get_args():
    p = argparse.ArgumentParser(description="Find git repos recursively and produce YAML code for ~/.config/repos.yml on STDOUT.  Use the --merge option to merge the results into the config file")
    p.add_argument("dirs", nargs='*', default=[os.getcwd()], help="Directories to search.  Searches PWD if none are specified")
    p.add_argument("--recursive", action='store_true', help="Search recursively")
    p.add_argument("--debug", action="store_true", help="Print current search dir to STDERR")
    p.add_argument("--merge", action='store_true', help="Merge with repo file")
    p.add_argument("-F", dest='repo_file', metavar="CONFIG_FILE", help="Alternate repo-file, defaults to ~/.config/repos.yml", default=os.path.expanduser("~/.config/repos.yml"))
    p.add_argument("--exclude", help="Regular expression to exclude")
    p.add_argument("--include", help="Regular expression to include")
    p.add_argument("--cleanup", action='store_true', help="Remove repos that don't exist anymore.  Only valid when using the --merge option")

    args = p.parse_args()
    if args.include and args.exclude:
        logger.error("Can only have one of --include or --exclude")
        p.parse_args(['-h'])
    if args.exclude:
        if '/' in args.exclude:
            logger.warning("--exclude pattern contains a '/' but pattern is used to match on path components")
        args.exclude = re.compile(args.exclude)
    if args.include:
        if '/' in args.include:
            logger.warning("--include pattern contains a '/' but pattern is used to match on path components")
        args.include = re.compile(args.include)

    for d in args.dirs:
        if not os.path.isdir(d):
            logger.warning(f"directory '{d}' does not exist or is not a directory")

    if args.debug:
        logger.setLevel(logging.DEBUG)

    return args

def is_git_repo(path):
    try:
        if not os.path.isdir(path):
            return False
        contents = os.listdir(path)

        if '.git' in contents:
            return True

        if 'branches' in contents and 'refs' in contents and 'objects' in contents and 'packed-refs' in contents:
            return True

    except PermissionError:
        return False

    return False

def find_git_repos(directory, recurse, args):
    logger.debug(f"Doing directory {directory}")

    if is_git_repo(directory):
        name = os.path.basename(directory)
        yield (name, {'path': directory})
        return

    if not os.path.isdir(directory):
        return

    if not recurse:
        return
    try:
        contents = os.listdir(directory)
    except PermissionError:
        return

    dirs = filter(lambda c: not c.startswith("."), contents)
    dirs = filter( lambda d:os.path.isdir(os.path.join(directory, d)), dirs)
    if args.exclude:
        dirs = filter(lambda d: not args.exclude.search(d), dirs)
    if args.include:
        dirs = filter(lambda d: args.include.search(d), dirs)
    for d in dirs:
        yield from find_git_repos(os.path.join(directory, d), args.recursive, args=args)

def soft_update(original, new):
    """ Update original with keys that are in new but not already in original """

def main():
    args = get_args()
    repos = {}
    try:
        for d in args.dirs:
            if not os.path.isabs(d):
                d = os.path.join(os.getcwd(), d)
            repos.update(find_git_repos(directory=d, recurse=True, args=args))
    except KeyboardInterrupt:
        logger.info("KeyboardInterrupt, results so far:")
        yaml.dump({'repos': repos})
        return 130
    if args.merge:
        if not os.path.exists(args.repo_file):
            open(args.repo_file, 'w').write('repos: {}\n')
        with open(args.repo_file, 'r') as f:
            base_rf = yaml.safe_load(f)
            for k in repos.keys():
                if k not in base_rf['repos']:
                    logger.info(f"Adding repo '{k}' at path '{repos[k]['path']}'")
                    base_rf['repos'][k] = repos[k]
        if args.cleanup:
            for k in list(base_rf['repos'].keys()):
                v = base_rf['repos'][k]
                if not os.path.isdir(v['path']):
                    logger.info(f"Deleting key {k}: path {v['path']} does not exist")
                    del base_rf['repos'][k]
        with open(args.repo_file, 'w') as f:
            yaml.dump(base_rf, f)
    else:
        print(yaml.dump({"repos": repos }))

sys.exit(main())
