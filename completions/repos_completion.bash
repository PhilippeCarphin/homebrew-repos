#
# This file was generated by autocomplete-generator https://gitlab.com/philippecaphin/autocomplete-generator
#

# This is the function that will be called when we press TAB.
#
# Its purpose is # to examine the current command line (as represented by the
# array COMP_WORDS) and to determine what the autocomplete should reply through
# the array COMPREPLY.
#
# This function is organized with subroutines who  are responsible for setting
# the 'candidates' variable.
#
# The compgen then filters out the candidates that don't begin with the word we are
# completing. In this case, if '--' is one of the words, we set empty candidates,
# otherwise, we look at the previous word and delegate # to candidate-setting functions
# NOTE:  Spack's environment setup defines a function '_repos' that is reused
# between its completion functions.  Therefore, it is better to call this
# function something else than that.
__complete_repos() {

	COMPREPLY=()
    # As it is, this assumes that the subcommand can only be the fist argument
    # of the repos command.  This is not enforced but it makes no sense to
    # specify options to repos before the subcommand except for `-F CONFIG_FILE`
    # but since this is not super likely.  If I really want to, I can do like
    # git_completion.bash to look through the words and find the subcommand that
    # way.  It is at the start of the function `__git_main`.

    local c=1
    local w=""
    local subcommand
    while (( c < COMP_CWORD )) ; do
        w=${COMP_WORDS[c]}
        case $w in
            -F) ((c++)) ;; # skip -F CONFIG_FILE
            -*) ;;
            *) subcommand="${w}" ; break ;;
        esac
        ((c++))
    done

	# We use the current word to filter out suggestions
	local cur="${COMP_WORDS[COMP_CWORD]}"

    case "${subcommand}" in
        find) _repos_find ; return ;;
        ignore) _repos_ignore ; return ;;
        del|add|ignore) _repos_del ; return ;;
        comment) _repos_comment ; return ;;
        clone) _repos_clone ; return ;;
        "") COMPREPLY+=( $(compgen -W "find ignore del add ignore comment clone" -- "${cur}" ));;
        *) printf "\n${FUNCNAME[0]}: unknown subcommand '%s'\n%s" "${subcommand}" "${PS1@P}${COMP_LINE}"
    esac

	if __repos_dash_dash_in_words ; then
		return
	fi

	option=$(__repos_get_current_option)
	if __repos_option_has_arg "$option" ; then
		__suggest_repos_args_for_option ${option}
	elif [[ "${cur}" == -* ]] ; then
		__suggest_repos_options
	fi

	return 0
}

__repos_dash_dash_in_words(){
	for ((i=0;i<COMP_CWORD;i++)) ; do
		w=${COMP_WORDS[$i]}
		if [[ "$w" == "--" ]] ; then
			return 0
		fi
	done
	return 1
}

__repos_get_current_option(){
	# The word before that
	local prev="${COMP_WORDS[COMP_CWORD-1]}"
	if [[ "$prev" == -* ]] ; then
		echo "$prev"
	fi
}

__suggest_repos_options(){
	candidates+=" -F -all -days -generate-config -get-dir -j -list-names -list-paths -no-fetch -noignore -path -r -recent"
}
__repos_option_has_arg(){
    local option=$1
    case "$1" in
        -get-dir|-F|-j|-days|-path) return 0 ;; # BASH True
        *) return 1 ;; # BASH False
    esac
}

__suggest_repos_args_for_option(){
	case "$1" in
		-generate-config) __suggest_repos_key_generate_config_values ;;
		-j) __suggest_repos_key_j_values ;;
		-list-names) __suggest_repos_key_list_names_values ;;
		-list-paths) return ;;
		-no-fetch) __suggest_repos_key_no_fetch_values ;;
		-path) __suggest_repos_key_path_values ;;
		-r|-get-dir) __suggest_repos_key_r_values ;;
        -recent) return ;;
        *) return ;;
	esac
}

__suggest_repos_key_generate_config_values(){
    COMPREPLY+=()
}

__suggest_repos_key_j_values(){
    printf "\n%s\n%s%s" "Nproc=$(nproc)" "${PS1@P}" "${COMP_LINE}"
}

__suggest_repos_key_list_names_values(){
    COMPREPLY+=()
}

__suggest_repos_key_no_fetch_values(){
    COMPREPLY+=()
}

__suggest_repos_key_path_values(){
    COMPREPLY+=()
}

__suggest_repos_key_r_values(){
    COMPREPLY+=( compgen -W "$(repos -list-names 2>/dev/null)" -- "${cur}" )
}

complete -F __complete_repos repos

function expand_repo_dir(){

    local repo_name=${1%%/*}
    local repo_subdir
    if [[ ${1} == */* ]] ; then
        repo_subdir=${1#*/}
    fi
    shift

    local repo_dir
    if ! repo_dir=$(repos -get-dir ${repo_name} "$@" 2>/dev/null) ; then
        return 1
    fi

    echo "${repo_dir}/${repo_subdir}"
}

function rcd(){
    case $1 in
        --help) man ${FUNCNAME[0]} ; return ;;
        -h)
        echo "rcd : 'repos-cd' is a shell function to cd to repos
by their names in ~/.config/repos.yml.  This function
has AUTOCOMPLETE based on the repos listed in ~/.config/repos.yml

Usage:

    rcd REPO-NAME/SUBDIR

See 'man rcd' or '${FUNCNAME[0]} --help' for more information."
        return ;;
    esac

    local dir
    if ! dir=$(expand_repo_dir $1) ; then
        _repos_error "No repo '$1' in ~/.config/repos.yml"
        return 1
    fi

    if [[ -v __shell_grayscale ]] ; then
        printf "cd $dir\n"
    else
        printf "\033[33mcd $dir\033[0m\n"
    fi
    cd $dir
}

function rvi(){
    local path
    if ! path=$(expand_repo_dir $1) ; then
        _repos_error "No repo '$1' in ~/.config/repos.yml"
        return 1
    fi
    vim $path
}

function _repos_error(){
    if [[ -v __shell_grayscale ]] ; then
        printf "${FUNCNAME[1]}: ERROR: $*\n" >&2
    else
        printf "${FUNCNAME[1]}: \033[1;31mERROR\033[0m: $*\n" >&2
    fi
}



function rmv(){
    local -a to_move
    local colon_found=false
    for tm in "$@" ; do
        if [[ ${tm} == ":" ]] ; then
            shift
            colon_found=true
            break
        fi
        shift
        to_move+=("${tm}")
    done
    if [[ "${colon_found}" == false ]] ; then
        _repos_error "rmv requires colon"
        return 1
    fi
    local dest=${1}
    if [[ -z "${dest}" ]] ; then
        _repos_error "Destination not specified"
        return 1
    fi

    local true_dest
    if ! true_dest=$(expand_repo_dir ${dest}) ; then
        _repos_error "No repo '$1' in ~/.config/repos.yml"
        return 1
    fi

    local display_true_dest=$(printf "%s\033[1m%s\033[0m/%s\n" \
        ${true_dest%%${dest}} ${dest%%/*} ${dest#*/})
    echo "mv ${to_move[@]} ${display_true_dest}"
    mv "${to_move[@]}" ${true_dest}
}

function __complete_rmv(){
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local prev="${COMP_WORDS[COMP_CWORD-1]}"
    if [[ ${prev} != ":" ]] ; then
        compopt -o default
        return
    fi
    __complete_rcd
}


__complete_rvi(){
	COMPREPLY=()
	# We use the current word to filter out suggestions
	local cur="${COMP_WORDS[COMP_CWORD]}"
	# Compgen: takes the list of candidates and selects those matching ${cur}.
	# Once COMPREPLY is set, the shell does the rest.

    local repo_name=${cur%%/*}
    local repo_subdir=${cur#*/}


    if [[ "${cur}" == */* ]] ; then
        if ! repo_dir=$(repos -get-dir ${repo_name} 2>/dev/null) ; then
            return
        fi
        compopt -o filenames
        local i=0
        # echo "\${repo_dir}/\${repo_subdir}=${repo_dir}/${repo_subdir}" >> ~/.log.txt
        local last_full_path
        for full_path in $(compgen -f -- ${repo_dir}/${repo_subdir}) ; do
            if [[ $(basename ${full_path}) == .* ]] ; then
                continue
            fi
            relative_path="${full_path##${repo_dir}}"
            #
            # The in its handling of CDPATH, the _cd function looks at
            # whether or not we configured readline to mark directories
            # with the 'set visible-stats on' option.  I should do that
            # too instead of doing it only when there is a single candidate
            #
            if [[ -d ${full_path} ]] ; then
                COMPREPLY[i++]="${repo_name}${relative_path}/"
            else
                COMPREPLY[i++]="${repo_name}${relative_path}"
            fi
            last_full_path=${full_path}
        done
        #
        # Turn on compopt -o nospace only when we have a single candidate and
        # we want completion to continue.  This is when the single candidate
        # is a non-empty directory.
        #
        if ((${#COMPREPLY[@]} == 1)) ; then
            if [[ -d ${last_full_path} ]] && __has_contents ${last_full_path} ; then
                compopt -o nospace
            fi
        fi;
    else
        COMPREPLY=( $(compgen -W "$(repos -list-names 2>/dev/null)" -- ${cur}))
        if ((${#COMPREPLY[@]} == 1)) ; then
            compopt -o nospace
            COMPREPLY[0]+=/;
        fi;
    fi
}
__complete_relative_dirs(){
    # Complete subdirs of container
    local container=$1
    local subdir=$2
    local prefix=$3
    compopt -o filenames
    local i=0
    # echo "\${repo_dir}/\${repo_subdir}=${repo_dir}/${repo_subdir}" >> ~/.log.txt
    local last_full_path
    for full_path in $(compgen -d -- ${container}/${subdir}) ; do
        if [[ $(basename ${full_path}) == .* ]] ; then
            continue
        fi
        # echo "full_path=${full_path}" >> ~/.log.txt
        relative_path="${full_path##${container}}"
        # echo "relative_path=${relative_path}" >> ~/.log.txt
        COMPREPLY[i++]="${prefix}${relative_path}"
    done
}

__has_subdirs(){
    if ! [[ -d $1 ]] ; then
        return 1
    fi
    # Note this command works for MacOS and Linux.  BSD find does not have
    # the -printf option.  It would be nicer to do `-printf . -quit` since
    # we only care about empty vs non-empty.  But since we only care about
    # empty vs non-empty, this works just as well.
    local res=$(find -L $1 -mindepth 1 -maxdepth 1 -type d -print -quit)
    (( ${#res} > 0 ))
}

__has_contents(){
    if ! [[ -d $1 ]] ; then
        return 1
    fi

    local res=$(find -L $1 -mindepth 1 -maxdepth 1 -print -quit)
    (( ${#res} > 0 ))
}


__complete_rcd(){
    __complete_rcd_internal
}



__complete_rcd_internal(){
    local repo_file=()
    if [[ -n "$1" ]] ; then
        repo_file=(-F "$1")
    fi

    COMPREPLY=()
    local cur="${COMP_WORDS[COMP_CWORD]}"

    compopt -o nospace
    if [[ "${cur}" != */* ]] ; then
        COMPREPLY=( $(compgen -W "$(repos -list-names "${repo_file[@]}" 2>/dev/null)" -- "${cur}"))
    else
        local repo_name=${cur%%/*}
        local repo_subdir=${cur#*/}
        if ! repo_dir=$(repos -get-dir ${repo_name} "${repo_file[@]}" 2>/dev/null) ; then
            return
        fi
        compopt -o filenames
        __complete_relative_dirs "${repo_dir}" "${repo_subdir}" "${repo_name}"
        local dir_to_check=${repo_dir}/${COMPREPLY[0]##${repo_name}/}
        if ((${#COMPREPLY[@]} == 1 )) && ! __has_subdirs ${dir_to_check} ; then
            compopt +o nospace
        fi
    fi
    if ((${#COMPREPLY[@]} == 1)) ; then
        COMPREPLY[0]+=/;
    fi;
}

orepos(){
    local name=$1 ; shift
    case $1 in
        --help) man ${FUNCNAME[0]} ; return ;;
        -h) printf "${FUNCNAME[0]} NAME [repos-arguments]\n\n\tShortcut for 'repos -F ~/.config/repos/\${NAME}.yml -no-fetch \"\$@\"\n" return ;;
    esac
    repos -F $HOME/.config/repos/${name}.yml -no-fetch "$@"
}

__complete_orepos(){
    local cur prev cword words
    _init_completion || return
    if ((cword == 1)) ; then
        COMPREPLY=($(cd $HOME/.config/repos ;
            for x in *.yml ; do
                if [[ "${x%%.yml}" == ${cur}* ]] ; then
                    echo "${x%%.yml}"
                fi
            done
        ))
    else
        __complete_repos
    fi
}

complete -F __complete_orepos orepos

orcd(){
    local repo_file_basename=$1
    local dir=$2
    if ! dir="$(expand_repo_dir ${dir} -F ${HOME}/.config/repos/${repo_file_basename}.yml)" ; then
        echo "${FUNCNAME[0]}: ERROR: Could not get directory of repo '${repo_name}' in '${HOME}/.config/${repo_file_basename}.yml'"
        return 1
    fi
    printf "\033[33mcd ${dir}\033[0m\n"
    cd "$dir"
}

__complete_orcd(){
    local cur prev cword words
    _init_completion || return
    if ((cword == 1)) ; then
        local x y
        for x in $HOME/.config/repos/*.yml ; do
            x=${x##*/}
            x=${x%%.yml}
            if [[ "${x}" == ${cur}* ]] ; then
                COMPREPLY+=(${x})
            fi
        done
    elif ((cword > 1)) ; then
        local repo_file=${HOME}/.config/repos/${words[1]}.yml
        if ! [[ -f ${repo_file} ]] ; then
            # Expected error.
            return 1
        fi
        if [[ ${cur} == */* ]] ; then
            __complete_rcd_internal ${repo_file}
        else
            COMPREPLY=($(compgen -S/ -W "$(repos -F ${repo_file} -list-names)" -- ${cur} ))
            compopt -o nospace
        fi
    fi
}
complete -F __complete_orcd orcd

_repo-ignore(){
    local prev=${COMP_WORDS[${COMP_CWORD}-1]}
    local cur=${COMP_WORDS[${COMP_CWORD}]}
    if [[ "${prev}" == "--name" ]] ; then
        COMPREPLY=( $(compgen -W "$(repos -list-names 2>/dev/null)" -- ${cur}) )
    else
        COMPREPLY=( $(compgen -W "--name --unignore" -- ${cur}))
    fi
}

_repos_del(){
    local prev=${COMP_WORDS[${COMP_CWORD}-1]}
    local cur=${COMP_WORDS[${COMP_CWORD}]}
    if [[ "${prev}" == "--name" ]] ; then
        COMPREPLY=( $(compgen -W "$(repos -list-names 2>/dev/null)" -- ${cur}) )
    else
        COMPREPLY=( $(compgen -W "--name -F" -- ${cur}))
    fi
}
_repos_comment(){
    local prev=${COMP_WORDS[${COMP_CWORD}-1]}
    local cur=${COMP_WORDS[${COMP_CWORD}]}
    case "${prev}" in
        name) COMPREPLY=( $(compgen -W "$(repos -list-names 2>/dev/null)" -- "${cur}") ) ; return ;;
        comment) return ;;
        -F) _filedir ; return ;;
    esac
    COMPREPLY=( $(compgen -W "--get --set --clear --name -F -h --help" -- "${cur}"))
}
_repos_find(){
    local prev=${COMP_WORDS[${COMP_CWORD}-1]}
    local cur=${COMP_WORDS[${COMP_CWORD}]}
    if [[ "${prev}" == "-F" ]] ; then
        _filedir
        return
    fi
    if ! __repos_dash_dash_in_words ; then
        COMPREPLY=( $(compgen -W " --exclude --include --merge --recursive --debug -F" -- "${cur}") )
    fi
    _filedir
}

_repos_get_domains(){
    local f=~/.config/repos.yml
    if ! [[ -f $f ]] ; then
        return 1
    fi
    python3 -c "import yaml; print('\n'.join(yaml.safe_load(open('$f'))['config']['domains'].keys()))"
}
_repos_get_domain_users(){
    local f=~/.config/repos.yml
    if ! [[ -f $f ]] ; then
        return 1
    fi
    python3 -c "import yaml; print('\n'.join(yaml.safe_load(open('$f'))['config']['domains']['$1']))"
}
_repos_complete_url(){

    local url=$1
    local x user domain
    case ${url} in
        git@*:*/*|https://*/*/) return ;;
        git@*:*)
            x=${url#git@} ; domain=${x%%:*} ; user=${x##*:}
            COMPREPLY+=( $(compgen -S / -W "$(_repos_get_domain_users ${domain})" -- "${user}") )
            ;;
        git@*)
            x=${url#git@} ; domain=${x%%:*}
            COMPREPLY+=( $(compgen -P "git@" -S : -W "$(_repos_get_domains)" -- "${domain}") )
            ;;
        https://*/*)
            x=${url#https://} ; user=${x##*/} ; domain=${x%%/${user}}
            COMPREPLY+=( $(compgen -P "https://${domain}/" -S / -W "$(_repos_get_domain_users ${domain})" -- "${user}") )
            ;;
        https://*)
            x=${url#https://} ; domain=${x%%:*}
            COMPREPLY+=( $(compgen -P "https://" -S / -W "$(_repos_get_domains)" -- "${domain}") )
            ;;
        *)
            COMPREPLY+=( $(compgen -W "https:// git@" -- "${url}") )
            ;;
    esac
}

_repos_clone(){
    local prev=${COMP_WORDS[${COMP_CWORD}-1]}
    local cur=${COMP_WORDS[${COMP_CWORD}]}
    if [[ "${prev}" == "-F" ]] ; then
        _filedir
        return
    fi

    local words cword
    __reassemble_comp_words_by_ref : words cword
    compopt -o nospace
    compopt +o default
    _repos_complete_url ${words[cword]}
}

complete -F _repo-del repo-del

complete -F _repo-ignore repo-ignore rign

complete -F __complete_rcd rcd
complete -F __complete_rvi rvi
complete -F __complete_rmv rmv

if ! [ -e ~/.config/repos.yml ] ; then
    printf "\033[33mrepos_completion.bash : WARNING: No '~/.config/repos.yml' file found.\n" >&2
    printf "The 'rcd' command and some subcommands of 'repos' need this file to exist\n" >&2
    printf "Consider doing \n" >&2
    printf "    'repos find DIR --merge [--recursive]'\n" >&2
    printf "to add all repos inside DIR to ~/.config/repos.yml or\n" >&2
    printf "    'repos add'\n" >&2
    printf "from within a git repository to add PWD as a git repo\033[0m\n" >&2
fi
