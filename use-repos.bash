this_file=$(python3 -c "import os; print(os.path.realpath('${BASH_SOURCE[0]}'))")
this_dir=$(cd $(dirname ${this_file}) && pwd)
if ! [ -e $this_dir/repos ] ; then
    echo "Please make sure there is an executable 'repos' in $this_dir."
    echo "You probably want to do 'mv repos_darwin_amd64 repos' if you are on an amd64'"

function repos(){
    ${this_dir}/repos "$@"
}

source ${this_dir}/completions/repos_completion.bash
