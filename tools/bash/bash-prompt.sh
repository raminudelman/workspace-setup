#!/usr/bin/env bash

function prompt_git() {
    local s='';
    local branchName='';

    # Check if the current directory is in a Git repository.
    if [ $(git rev-parse --is-inside-work-tree &>/dev/null; echo "${?}") == '0' ]; then

        # check if the current directory is in .git before running git checks
        if [ "$(git rev-parse --is-inside-git-dir 2> /dev/null)" == 'false' ]; then

            # Ensure the index is up to date.
            git update-index --really-refresh -q &>/dev/null;

            # Check for uncommitted changes in the index.
            if ! $(git diff --quiet --ignore-submodules --cached); then
                s+='+';
            fi;

            # Check for unstaged changes.
            if ! $(git diff-files --quiet --ignore-submodules --); then
                s+='!';
            fi;

            # Check for untracked files.
            if [ -n "$(git ls-files --others --exclude-standard)" ]; then
                s+='?';
            fi;

            # Check for stashed files.
            if $(git rev-parse --verify refs/stash &>/dev/null); then
                s+='$';
            fi;

        fi;

        # Get the short symbolic ref.
        # If HEAD isn’t a symbolic ref, get the short SHA for the latest commit
        # Otherwise, just give up.
        branchName="$(git symbolic-ref --quiet --short HEAD 2> /dev/null || \
            git rev-parse --short HEAD 2> /dev/null || \
            echo '(unknown)')";

        [ -n "${s}" ] && s=" [${s}]";

        echo -e "${1}${branchName}${2}${s}";
    else
        echo -e " ${2}(not in git repo)";
        return;
    fi;
}


# Define the 8 default colors using the default coloring that every terminal 
# supports
bold='';
rst="\[\e[0m\]";

regblk="\[\e[0;30m\]"; # Regular Black
regred="\[\e[0;31m\]"; # Regular Red
reggrn="\[\e[0;32m\]"; # Regular Green
regylw="\[\e[0;33m\]"; # Regular Yellow
regblu="\[\e[0;34m\]"; # Regular Blue
regmag="\[\e[0;35m\]"; # Regular Magenta
regcyn="\[\e[0;36m\]"; # Regular Cyan
regwht="\[\e[0;37m\]"; # Regular White
regrng="\[\e[0;33m\]"; # Regular Orange (Same as Regular Yellow)
regvio="\[\e[0;35m\]"; # Regular Violet (Same as Regular Magenta)

bldblk="\[\e[1;30m\]"; # Bold Black
bldred="\[\e[1;31m\]"; # Bold Red
bldgrn="\[\e[1;32m\]"; # Bold Green
bldylw="\[\e[1;33m\]"; # Bold Yellow
bldblu="\[\e[1;34m\]"; # Bold Blue
bldmag="\[\e[1;35m\]"; # Bold Magenta
bldcyn="\[\e[1;36m\]"; # Bold Cyan
bldwht="\[\e[1;37m\]"; # Bold White
bldrng="\[\e[1;33m\]"; # Bold Orange (Same as Bold Yellow)
bldvio="\[\e[1;35m\]"; # Bold Violet (Same as Bold Magenta)

undblk="\[\e[4;30m\]"; # Underlined Black
undred="\[\e[4;31m\]"; # Underlined Red
undgrn="\[\e[4;32m\]"; # Underlined Green
undylw="\[\e[4;33m\]"; # Underlined Yellow
undblu="\[\e[4;34m\]"; # Underlined Blue
undmag="\[\e[4;35m\]"; # Underlined Magenta
undcyn="\[\e[4;36m\]"; # Underlined Cyan
undwht="\[\e[4;37m\]"; # Underlined White
undrng="\[\e[4;33m\]"; # Underlined Orange (Same as Underlined Yellow)
undvio="\[\e[4;35m\]"; # Underlined Violet (Same as Underlined Magenta)

bakblk="\[\e[40m\]"; # Background Black
bakred="\[\e[41m\]"; # Background Red
bakgrn="\[\e[42m\]"; # Background Green
bakylw="\[\e[43m\]"; # Background Yellow
bakblu="\[\e[44m\]"; # Background Blue
bakmag="\[\e[45m\]"; # Background Magenta
bakcyn="\[\e[46m\]"; # Background Cyan
bakwht="\[\e[47m\]"; # Background White
bakrng="\[\e[43m\]"; # Background Orange (Same as Background Yellow)
bakvio="\[\e[45m\]"; # Background Violet (Same as Background Magenta)

# Define the colors in case there is support in the terminal for 256 colors
if tput setaf 1 &> /dev/null; then
    # Capname 			Description
    # bold 				Start bold text
    # smul 				Start underlined text
    # rmul 				End underlined text
    # rev 				Start reverse video
    # blink 			Start blinking text
    # invis 			Start invisible text
    # smso 				Start "standout" mode
    # rmso 				End "standout" mode
    # sgr0 				Turn off all attributes
    # setaf  <value>	Set foreground color
    # setab  <value>	Set background color

    tput sgr0; # reset colors
    bold="\[$(tput bold)\]";
    rst="\[$(tput sgr0)\]"; # Reset
    
    # Solarized colors, taken from http://git.io/solarized-colors.
    txtblk="\[$(tput setaf 0)\]";   # Regular Black
    txtred="\[$(tput setaf 160)\]"; # Regular Red
    txtgrn="\[$(tput setaf 64)\]";  # Regular Green
    txtylw="\[$(tput setaf 136)\]"; # Regular Yellow
    txtblu="\[$(tput setaf 33)\]";  # Regular Blue
    txtmag="\[$(tput setaf 125)\]"; # Regular Magenta
    txtcyn="\[$(tput setaf 37)\]";  # Regular Cyan
    txtwht="\[$(tput setaf 15)\]";  # Regular White
    txtrng="\[$(tput setaf 166)\]"; # Regular Bright Red
    txtvio="\[$(tput setaf 61)\]";  # Regular Bright Magenta
    
    bldblk="\[$(tput bold)$(tput setaf 0)\]";   # Bold Black
    bldred="\[$(tput bold)$(tput setaf 160)\]"; # Bold Red
    bldgrn="\[$(tput bold)$(tput setaf 64)\]";  # Bold Green
    bldylw="\[$(tput bold)$(tput setaf 136)\]"; # Bold Yellow
    bldblu="\[$(tput bold)$(tput setaf 33)\]";  # Bold Blue
    bldmag="\[$(tput bold)$(tput setaf 125)\]"; # Bold Magenta
    bldcyn="\[$(tput bold)$(tput setaf 37)\]";  # Bold Cyan
    bldwht="\[$(tput bold)$(tput setaf 15)\]";  # Bold White
    bldrng="\[$(tput bold)$(tput setaf 166)\]"; # Bold Bright Red
    bldvio="\[$(tput bold)$(tput setaf 61)\]";  # Bold Bright Magenta
fi

# Highlight the user name when logged in as root.
if [ "${UID}" -eq "0" ]; then # Same as: 'if [[ "${USER}" == "root" ]]; then'
    userInfo="${bldmag}\u${rst}";
else
    userInfo="${bldrng}\u${rst}";
fi;

# Hostname
hostInfo="${bldylw} \h${rst}";

# Shows only the last two directories in the prompt path
#PROMPT_DIRTRIM=2

# Working directory full path
dirInfo="${bldgrn} \w";

# If called with '1' as argument, add the git information.
# If called with '0' as argument, does not include the git information.
function ps1_format() {
    include_git=$1
    PS1=""; # Initialize as empty
    PS1+="\n"; # New line
    PS1+="${bldblu}[${bldblu}\\t${bldblu}] ";
    PS1+="${userInfo}"; # Username
    PS1+="${bldwht} at";
    PS1+="${hostInfo}"; # Hostname
    PS1+="${bldwht} in";
    PS1+="${dirInfo}"; # Working directory full path
    if [[ ${include_git} -eq 1 ]]; then
        PS1+="\$(prompt_git \"${bldwht} on ${bldvio}\" \"${bldblu}\")"; # Git repository details
    fi
    PS1+="\n"; # New line
    PS1+="${bldwht}\$ "; # Add '$'
    PS1+="${rst}"; # Reset color
    export PS1;
}

# An easy "alias" to format the prompt without git information
function ps1_git_no() {
    ps1_format 0;
}

# An easy "alias" to format the prompt with git information
function ps1_git_yes() {
    ps1_format 1;
}

# By default, use the prompt without 
ps1_format 0

PS2="${bldylw}→ ${rst}";
export PS2;

################################################################################

# ##################
# ### Git Version 2
# ##################

# # Get current branch in git repo
# function parse_git_branch() {
#     #echo ""; return 0 # Uncomment for disabling git integration into the prompt
#     BRANCH=`git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
#     if [ ! "${BRANCH}" == "" ]; then
# 		STAT=`parse_git_dirty`
# 		echo "[${BRANCH}${STAT}]"
# 	else
# 		echo ""
# 	fi
# }

# # Get current status of git repo
# function parse_git_dirty {
#     status=`git status 2>&1 | tee`
#     dirty=`echo -n "${status}" 2> /dev/null | grep "modified:" &> /dev/null; echo "$?"`
#     untracked=`echo -n "${status}" 2> /dev/null | grep "Untracked files" &> /dev/null; echo "$?"`
#     ahead=`echo -n "${status}" 2> /dev/null | grep "Your branch is ahead of" &> /dev/null; echo "$?"`
#     newfile=`echo -n "${status}" 2> /dev/null | grep "new file:" &> /dev/null; echo "$?"`
#     renamed=`echo -n "${status}" 2> /dev/null | grep "renamed:" &> /dev/null; echo "$?"`
#     deleted=`echo -n "${status}" 2> /dev/null | grep "deleted:" &> /dev/null; echo "$?"`
#     bits=''
#     if [ "${renamed}" == "0" ]; then
# 		bits=">${bits}"
# 	fi
#     if [ "${ahead}" == "0" ]; then
# 		bits="*${bits}"
# 	fi
#     if [ "${newfile}" == "0" ]; then
# 		bits="+${bits}"
# 	fi
#     if [ "${untracked}" == "0" ]; then
# 		bits="?${bits}"
# 	fi
#     if [ "${deleted}" == "0" ]; then
# 		bits="x${bits}"
# 	fi
#     if [ "${dirty}" == "0" ]; then
# 		bits="!${bits}"
# 	fi
#     if [ ! "${bits}" == "" ]; then
# 		echo " ${bits}"
# 	else
# 		echo ""
# 	fi
# }


# GIT_BRANCH="$cyn\$(parse_git_branch)"
# PS1=$GIT_BRANCH$rst\n\$"
