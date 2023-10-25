#!/usr/bin/env python3

import sys
import yaml
import argparse
import os
import subprocess

def get_args():
    p = argparse.ArgumentParser(description="Clone a git repo into repository tree and add it to repo file")

    p.add_argument("-F", help="Specify alternate file to ~/.config/repos.yml")
    p.add_argument("url", help="Repository URL to clone", nargs=1)
    p.add_argument("--name", help="Specify name for repo in config file")

    if "FROM_REPOS" in os.environ:
        print(f"DEBUG: Called by repos executable by doing 'repos clone'")

    args = p.parse_args()

    args.url = args.url[0]

    return args

def main():
    args = get_args()
    print(args)
    #
    # Load repofile
    #
    repo_file = args.F if args.F else os.path.expanduser("~/.config/repos.yml")
    with open(repo_file) as y:
        repo_dict = yaml.safe_load(y)

    repo_dest = get_repo_dest(args, repo_dict)

    try:
        os.makedirs(os.path.dirname(repo_dest), exist_ok=True)
    except OSError as e:
        print(f"Could not create container directory: {e}")
        return 1

    result = subprocess.run(["git", "clone", args.url, repo_dest])
    if result.returncode != 0:
        print(f"repos-clone: failed to clone '{args.url}'")
        return 1
    if args.name:
        result = subprocess.run(["repos", "add", repo_dest, "--name", args.name])
    else:
        result = subprocess.run(["repos", "add", repo_dest])
    if result.returncode != 0:
        print(f"repos-clone: ERROR adding repo")
        return 1

def get_repo_dest(args, repo_dict):

    repo_basename = os.path.basename(args.url)

    if 'config' not in repo_dict:
        print(f"repos-clone is more useful when config file has a config section.  See section CONFIGURATION in 'man repos'")
        return os.path.join(os.environ['PWD'], repo_basename)

    config = repo_dict['config']
    if 'repo-dir' not in config:
        print(f"repos-clone: no key 'repo-dir' in config section of {repo_file}")
        return os.path.join(os.environ['PWD'], repo_basename)

    if 'repo-dir-scheme' not in config:
        print(f"repos-clone no key 'repo-dir-scheme' in config section of {repo_file}")
        return os.path.join(config['repo-dir'], repo_basename)

    scheme = config['repo-dir-scheme']
    if scheme == "url":
        return os.path.join(config['repo-dir'], url_to_directory(args.url))
    elif scheme == "flat":
        return os.path.join(config['repo-dir'], repo_basename)
    elif scheme == "none":
        return os.path.join(config['repo-dir'], repo_basename)
    else:
        raise RuntimeError(f"repos-clone: Unrecognized value for repo-dir-scheme: '{scheme}'")

    return repo_dest


def url_to_directory(url):
    if url[0:4] == 'git@':
        return url[4:].replace(':', '/')
    elif url[:8] == 'https://':
        return url[8:]
    else:
        raise RepoError(f"URL '{url}' must begin with either 'git@' or 'https://'")

if __name__ == "__main__":
    sys.exit(main())
