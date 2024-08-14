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
__complete_repos() {

	COMPREPLY=()

	# We use the current word to filter out suggestions
	local cur="${COMP_WORDS[COMP_CWORD]}"
    local candidates=""
     __suggest_repos_candidates

	# Compgen: takes the list of candidates and selects those matching ${cur}.
	# Once COMPREPLY is set, the shell does the rest.
	COMPREPLY=( $(compgen -W "${candidates}" -- ${cur}))

	return 0
}

__suggest_repos_candidates(){
	# We use the current word to decide what to do
	local cur="${COMP_WORDS[COMP_CWORD]}"
	if __repos_dash_dash_in_words ; then
		return
	fi

	option=$(__repos_get_current_option)
	if __repos_option_has_arg "$option" ; then
		__suggest_repos_args_for_option ${option}
	else
		# No positional arguments yet
		__suggest_repos_options
	fi
}

__repos_dash_dash_in_words(){
	for ((i=0;i<COMP_CWORD-1;i++)) ; do
		w=${COMP_WORD[$i]}
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
	candidates="-F -all -days -generate-config -get-dir -j -list-names -list-paths -no-fetch -noignore -path -r -recent"
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
	candidates=""
}

__suggest_repos_key_j_values(){
	candidates=""
}

__suggest_repos_key_list_names_values(){
	candidates=""
}

__suggest_repos_key_no_fetch_values(){
	candidates=""
}

__suggest_repos_key_path_values(){
	candidates=""
}

__suggest_repos_key_r_values(){
    candidates="$(repos -list-names 2>/dev/null)"
}

complete -o default -F __complete_repos repos

function expand_repo_dir(){

    local repo_name=${1%%/*}

    local repo_subdir
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
        echo "rcd : 'repos-cd' is a shell function to cd to repos
by their names in ~/.config/repos.yml.  This function
has AUTOCOMPLETE based on the repos listed in ~/.config/repos.yml

Usage:

    rcd REPO-NAME

See 'man rcd' for more information."
        return
    fi

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
            if [[ -d ${last_full_path} ]] ; then
                if ! [[ $(find ${last_full_path} -maxdepth 1) == ${last_full_path} ]] ; then
                    compopt -o nospace
                fi
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

__complete_rcd(){
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
        for full_path in $(compgen -d -- ${repo_dir}/${repo_subdir}) ; do
            if [[ $(basename ${full_path}) == .* ]] ; then
                continue
            fi
            # echo "full_path=${full_path}" >> ~/.log.txt
            relative_path="${full_path##${repo_dir}}"
            # echo "relative_path=${relative_path}" >> ~/.log.txt
            COMPREPLY[i++]="${repo_name}${relative_path}"
            last_full_path=${full_path}
        done
        if ((${#COMPREPLY[@]} == 1)) ; then
            if ! [[ $(find ${last_full_path} -maxdepth 1 -type d) == ${last_full_path} ]] ; then
                compopt -o nospace
                COMPREPLY[0]+=/;
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

_repo-ignore(){
    local prev=${COMP_WORDS[${COMP_CWORD}-1]}
    local cur=${COMP_WORDS[${COMP_CWORD}]}
    if [[ "${prev}" == "--name" ]] ; then
        COMPREPLY=( $(compgen -W "$(repos -list-names 2>/dev/null)" -- ${cur}) )
    else
        COMPREPLY=( $(compgen -W "--name --unignore" -- ${cur}))
    fi
}

_repo-del(){
    local prev=${COMP_WORDS[${COMP_CWORD}-1]}
    local cur=${COMP_WORDS[${COMP_CWORD}]}
    if [[ "${prev}" == "--name" ]] ; then
        COMPREPLY=( $(compgen -W "$(repos -list-names 2>/dev/null)" -- ${cur}) )
    else
        COMPREPLY=( $(compgen -W "--name -F" -- ${cur}))
    fi
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
    printf "from within a git repository to add PWD as a git repo\n" >&2
fi
