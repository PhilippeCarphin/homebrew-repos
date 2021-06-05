#!/usr/bin/env python3
import os
import yaml

def is_git_repo(path):
    try:
        if not os.path.isdir(path):
            return False
        for d in os.listdir(path):
            if d.endswith(".git"):
                return True
    except PermissionError:
        return False
    return False

def find_git_repos(directory):
    if is_git_repo(directory):
        yield directory
        return
    if not os.path.isdir(directory):
        return
    # print(directory)
    try:
        contents = os.listdir(directory)
    except PermissionError:
        return
    #print(contents)
    new = filter(lambda c: not c.startswith("."), contents)
    subdirs = list(filter( lambda d:os.path.isdir(os.path.join(directory, d)), new))
    for d in subdirs:
        yield from find_git_repos(os.path.join(directory, d))

home_dirs = [
    "go/src/gitlab.com/philippecarphin",
    "go/src/github.com/philippecarphin",
    "go/src/gitlab.science.gc.ca",
    "fs1/Cellar/Repositories",
    "fs2/Cellar/Repositories",
    "fs3/Cellar/Repositories",
    "workspace",

    "Projects"
]
repos = []
for d in home_dirs:
    new_repos = list(find_git_repos(os.getcwd() + "/" + d))
    repos += new_repos
# repos = list(find_git_repos(os.getcwd()+"/workspace"))
# repos += list(find_git_repos(os.getcwd()+"/Documents/GitHub"))
# repos += list(find_git_repos(os.getcwd()+"/go/src/gitlab.com/philippecarphin"))
# repos += list(find_git_repos(os.getcwd()+"/go/src/github.com/philippecarphin"))
# repos += list(find_git_repos(os.getcwd()+"/go/src/gitlab.science.gc.ca"))
# repos += list(find_git_repos(os.getcwd()+"/go/src/gitlab.science.gc.ca"))
repos_file = {
        "repos": {os.path.basename(r):{"path":r} for r in repos}
}


print(yaml.dump(repos_file))


