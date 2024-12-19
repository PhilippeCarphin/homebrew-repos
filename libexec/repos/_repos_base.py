import subprocess
import os
import pathlib

import _repos_logging
logger = _repos_logging.logger

def get_repo_root(d=None):
    p = pathlib.Path(d).absolute()
    lastgit = p if p.joinpath('.git').is_dir() else None
    for x in p.parents:
        logger.debug(f"Checking path {x}")
        if x.joinpath('.git').is_dir():
            lastgit = x
    return lastgit
    # while True:
    #     if not p:
    #         return None
    #     cur = os.path.join(*p)
    #     print(cur)
    #     piss = os.path.join(cur, '.git')
    #     print(piss)
    #     if os.path.isdir(piss):
    #         return cur
    #     p.pop()

if __name__ == "__main__":
    print(get_repo_root(os.path.dirname(__file__)))

