#!/bin/zsh

autoload -U compinit
compinit

compdef _rcd rcd
rcd(){
    dir=$(repos -get-dir $1)
    echo "[33mcd $dir[0m"
    cd ${dir}
}

_rcd(){
    _arguments -C "1: :($(repos -list-names | tr '\n' ' '))"
}

compdef _repos repos
_repos(){
    _arguments -C "-h[Help]" "-r: :($(repos -list-names | tr '\n' ' '))"
}
