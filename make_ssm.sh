#!/bin/bash

# NOTE: This uses an unpublished ssm package creation tool, please see
# Philippe Carphin for more info.

spkg-buildpackage \
    --name ec-git-tools \
    --description "Extra tools for git things" \
    --version 0.7.0 \
    --sourced-file share/ec-git-tools/git-prompt-with-setup.sh
