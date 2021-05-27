#!/bin/zsh

autoload -U compinit
compinit

compdef _rcd rcd
rcd(){
    cd $(repos -get-dir $1)
}

_rcd(){
    _arguments -C "1: :($(repos -list-names | tr '\n' ' '))"
}

compdef _repos repos
_repos(){
    _arguments -C "-h[Help]" "-r: :($(repos -list-names | tr '\n' ' '))"
}
