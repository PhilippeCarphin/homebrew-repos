#!/bin/bash

# NOTE: This uses an unpublished ssm package creation tool, please see
# Philippe Carphin for more info.

spkg-buildpackage \
    --name repos \
    --description "Phil's repo thing" \
    --version $(git describe | tr -d 'v') \
    --sourced-file etc/bash_completion.d/repos_completion.bash
