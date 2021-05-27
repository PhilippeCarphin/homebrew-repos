#!/bin/zsh

this_file=$(python3 -c "import os; print(os.path.realpath('$_'))")
echo "this_file = $this_file"

if ! which repos >/dev/null ; then
    echo "this_dir = $this_dir"
    if ! [ -e $this_dir/repos ] ; then
        echo "Please make sure there is an executable 'repos' in $this_dir."
        echo "You probably want to do 'mv repos_darwin_amd64 repos' if you are on an amd64'"
        echo "or if you cloned the repo, you would want to build using 'go build .'"
        return 8
    fi

    function repos(){
        ${this_dir}/repos "$@"
    }
fi

function rcd(){
    cd $(repos -get-dir $1)
}

source ${this_dir}/completions/repos_completion.zsh

