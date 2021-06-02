function rcd
    set -l dir (repos -get-dir $argv[1])
    echo "[33mcd $dir[0m"
    cd $dir
end
complete -f -c rcd -a '(repos -list-names)'

complete -f -c repos -n 'contains -- -r (commandline -opc)' -a '(repos -list-names)'
complete -f -c repos  -a '-generate-config' -d 'Generate a config file on STDOUT from repos in PWD'
complete -f -c repos  -a '-no-fetch' -d 'Skip fetching step'
complete -f -c repos  -a '-days' -d 'Skip fetching step'
