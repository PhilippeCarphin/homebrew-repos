#!/bin/bash

# NOTE: This uses an unpublished ssm package creation tool, please see
# Philippe Carphin for more info.

# Note: The '--all' is because without it, 'git describe' only considers
# annotated tags.
repos_version=$(git describe --tags --always --dirty | tr -d 'v')
name=repos
arch=all

case "${repos_version}" in
    "")
        printf "\033[1;31mERROR\033[0m : Error running 'git describe ...' to get version\n" >&2
        exit 1
        ;;
    */*)
        printf "\033[1;31mERROR\033[0m : repo_version='${repos_version}' contains a '/'\n" >&2
        exit 1
        ;;
    *g*)
        printf "\033[1;31mERROR\033[0m : repo_version='${repos_version}' is not exact\n" >&2
        exit 1
        ;;
    *-dirty)
        printf "\033[1;31mERROR\033[0m : repo_version='${repos_version}' is dirty\n" >&2
        exit 1
        ;;
esac

spkg-buildpackage \
    --name repos \
    --description "Phil's repo thing" \
    --version ${repos_version} \
    --sourced-file etc/bash_completion.d/repos_completion.bash

# spkg-trypackage ../${name}_${repos_version}_${arch}.ssm ~/site5/ssm/${name}_${repos_version}_${arch}

