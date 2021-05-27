function rcd
    set -l dir (repos -get-dir $argv[1])
    echo "[33mcd $dir[0m"
    cd $dir
end

complete -f -c repos -n 'contains -- -r (commandline -opc)' -a '(repos -list-names)'

complete -f -c rcd -a '(repos -list-names)'
