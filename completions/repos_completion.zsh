#!/bin/zsh

autoload -U compinit
compinit

function expand_repo_dir(){

    local repo_name=${1%%/*}

    local repo_subdir=""
    if [[ ${1} == */* ]] ; then
        repo_subdir=${1#*/}
    fi

    local repo_dir
    if ! repo_dir=$(repos -get-dir ${repo_name} 2>/dev/null) ; then
        return 1
    fi

    echo "${repo_dir}/${repo_subdir}"
}


function rcd(){
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]] ; then
        __rcd_help
        return
    fi

    local dir
    if ! dir=$(expand_repo_dir $1) ; then
        printf "${funcstack[1]}: \033[1;31mERROR\033[0m: Could not expand repo_dir'${1}'\n" >&2
        return 1
    fi
    printf "\033[33mcd $dir\033[0m\n"
    cd $dir
}


function __rcd_help()
{
    echo "rcd : 'repos-cd' is a shell function to cd to repos
by their names in ~/.config/repos.yml.  This function
has AUTOCOMPLETE based on the repos listed in ~/.config/repos.yml

Usage:

    rcd REPO-NAME

See 'man rcd' for more information."
}


function _rcd(){
    local cur="${words[-1]}"
    local repo_name=${cur%%/*}
    local repo_subdir=${cur#*/}
    if [[ "${cur}" == */* ]] ; then
        _rcd_complete_subdirectories
    else
        _rcd_complete_repo_names
    fi
}


function _rcd_complete_repo_names(){
    candidates=($(repos -list-names 2>/dev/null | grep "^${cur}"))
    if ((${#candidates[@]} == 1 )) ; then
        compadd -Q -S '' "${candidates[1]}/"
        return 0
    else
        for c in "${candidates[@]}" ; do
            if [[ "${c}" = ${cur}* ]] ; then
                compadd -Q -S '' "${c}"
                :
            fi
        done
    fi
}


function _rcd_complete_subdirectories(){
    if ! repo_dir=$(repos -get-dir ${repo_name} 2>/dev/null) ; then
        return
    fi
    local -a valid_candidates=()
    local i=0
    local last_full_path
    local candidates=($(ls --color=never -d ${repo_dir}/${repo_subdir}*))
    for full_path in "${candidates[@]}" ; do
        if [[ -d ${full_path} ]] ; then
            local inner_path="${full_path##${repo_dir}}"
            valid_candidates+=("${repo_name}${inner_path}")
            last_full_path=${full_path}
        fi
    done
    if ((${#valid_candidates[@]} == 1)) ; then
        if contains_directories ${last_full_path} ; then
            compadd -Q -S '' "${valid_candidates[1]}/"
        else
            compadd -Q -S '' "${valid_candidates[1]}/ "
        fi
    else
        compset -P '*/'
        compset -S '/*'
        valid_candidates=(${valid_candidates##*/})
        valid_candidates=(${valid_candidates%%/*})
        compadd -S '' -Q -f -a valid_candidates
    fi;
}


function contains_directories(){
    ! [[ $(find ${1} -maxdepth 1 -type d) == ${1} ]]
}


compdef _rcd rcd

compdef _repos repos
_repos(){
    _arguments -C "-F:" "-all" "-days:" "-generate-config" "-get-dir: :($(repos -list-names | tr '/n' ' '))" "-j:" "-list-names" "-list-paths" "-no-fetch" "-noignore" "-path:" "-r:" "-recent"
    _arguments -C "-h[Help]" "-r: :($(repos -list-names | tr '\n' ' '))"
    _arguments -C "1: :(add del find ignore)"
}
