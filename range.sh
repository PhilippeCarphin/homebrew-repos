#!/bin/bash

git log --date=iso --pretty=format:'%ad%x08%aN' | awk '$0 >= "2021-05-28" && $0 <= "2021-05-29"'
