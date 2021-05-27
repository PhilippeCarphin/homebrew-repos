#!/bin/zsh

this_file=$(python3 -c "import os; print(os.path.realpath('${BASH_SOURCE[0]}'))")
echo "this_file = $this_file"
this_dir=$(cd $(dirname ${this_file}) && pwd)

echo "this_dir = $this_dir"
if ! [ -e $this_dir/repos ] ; then
    echo "Please make sure there is an executable 'repos' in $this_dir."
    echo "You probably want to do 'mv repos_darwin_amd64 repos' if you are on an amd64'"
fi


function repos(){
    ${this_dir}/repos "$@"
}

function rcd(){
    cd $(repos -get-dir $1)
}

source ${this_dir}/completions/repos_completion.zsh

