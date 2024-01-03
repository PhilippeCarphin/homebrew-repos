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
    if ! repo_dir=$(repos -get-dir ${repo_name}) ; then
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
        _rcd_complete_files only_dirs
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

function rvi(){
    local expanded_args=()
    local file
    local expanded_file
    for arg in "$@" ; do
        if expanded_file=$(expand_repo_dir $arg 2>/dev/null) ; then
            expanded_args+=("${expanded_file}")
        else
            printf "${funcstack[1]}: INFO: Could not expand repo_dir '${arg}'\n" >&2
            expanded_args+=("${arg}")
        fi
    done
    vim -p "${expanded_args[@]}"
}

function _rvi(){
    local cur="${words[-1]}"
    local repo_name=${cur%%/*}
    local repo_subdir=${cur#*/}
    if [[ "${cur}" == */* ]] ; then
        _rcd_complete_files
    else
        _rcd_complete_repo_names
    fi
}

function _rcd_complete_files(){
    if ! repo_dir=$(repos -get-dir ${repo_name} 2>/dev/null) ; then
        return
    fi
    local only_dirs="${1}"
    local -a basename_candidates=()
    local i=0
    local last_abs_path

    #
    # Obtain candidates.  Note that for repo_dir/empty/, this array will
    # contain a single element '.' which must be filtered out
    #
    local abs_candidates=($(ls --color=never -d ${repo_dir}/${repo_subdir}*(N)))

    #
    # Tell the completion system that the candidates we will be adding with
    # compadd are the part that comes after the '/' on the command line so
    # to complete 'a/b/c' to 'a/b/cde' or 'a/b/cxy' we will compadd 'cde' and
    # 'cxy'.  The double-tab menu will only show 'cde' and 'cxy'.  This makes
    # completion behave like 'compopt -f' in BASH.
    #
    compset -P '*/'

    #
    # Filter candidates.  Go from absolute paths to basenames while removing
    # non-directories if necessary and filtering out '.'.
    # As in BASH's _cd completion function we add a '/' to directories so that
    # they are marked with a '/' in the double-tab menu.  In BASH's _cd, the
    # function only does this if the readline options 'mark-directories' and
    # 'mark-simlinked-directories' are on.  I just always do it.
    #
    local basename
    for abs_path in "${abs_candidates[@]}" ; do
        if [[ -n "${only_dirs}" ]] && ! [[ -d "${abs_path}" ]] ; then
            continue
        fi
        if [[ "${abs_path}" == "." ]] ; then
            continue
        fi

        basename="${abs_path##*/}"
        if [[ -d ${abs_path} ]] ; then
            basename_candidates+=("${basename}/")
        else
            basename_candidates+=("${basename}")
        fi

        # abs_path corresponding the single candidate if there is one
        last_abs_path=${abs_path}
    done

    #
    # End or don't end completion if there is a single candidate
    #
    if ((${#basename_candidates[@]} == 1)) ; then
        local single_candidate=${basename_candidates[1]}
        if _rcd_end_completion "${1}" ; then
            single_candidate+=" "
        fi
        compadd -Q -S '' "${single_candidate}"
    #
    # End or don't end completion if there are no candidates.  In this case
    # we just check if what we have on the command line represents a valid
    # directory or file (this happens with repo/empty/_ which is the case
    # where our ls commands gives '.').
    #
    elif ((${#basename_candidates[@]} == 0)) ; then
        if ([[ "${1}" == only_dirs ]] && [[ -d ${repo_dir}/${repo_subdir} ]]) || [[ -e ${repo_dir}/${repo_subdir} ]] ;then
            compadd -Q -S '' " "
        fi
    #
    # And if there are more than one candidates, then we don't do anything
    # special.
    #
    else
        compadd -S '' -Q -f -a basename_candidates
    fi;
}

function _rcd_end_completion(){
    if [[ -n "${only_dirs}" ]] ; then
        [[ -d "${last_abs_path}" ]] && ! _rcd_contains_directories "${last_abs_path}"
    else
        [[ -f "${last_abs_path}" ]] || ( [[ -d "${last_abs_path}" ]] && ! _rcd_contains_anything "${last_abs_path}" )
    fi
}

function _rcd_contains_directories(){
    ! (( $(find ${1} -maxdepth 1 -type d | wc -l) == 1 ))
}

function _rcd_contains_anything(){
    ! (( $(find ${1} -maxdepth 1 | wc -l) == 1 ))
}



compdef _rcd rcd
compdef _rvi rvi

compdef _repos repos
_repos(){
    _arguments -C "-F:" "-all" "-days:" "-generate-config" "-get-dir: :($(repos -list-names | tr '/n' ' '))" "-j:" "-list-names" "-list-paths" "-no-fetch" "-noignore" "-path:" "-r:" "-recent"
    _arguments -C "-h[Help]" "-r: :($(repos -list-names | tr '\n' ' '))"
    _arguments -C "1: :(add del find ignore)"
}
