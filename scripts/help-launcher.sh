# Shared project launcher for a box running more than one thing — an fzf
# menu of every project, each showing its own command list.
#
# Convention: each project drops one plain-text file in help.d/ named
# <project>.help listing its own commands. Running `help` lists that
# directory and cats whichever file you pick. Adding a new project's
# commands never means editing this file or anyone else's — just add
# your own <project>.help.
#
# Install: copy into ~/.bash_aliases on the server, and `mkdir -p
# ~/help.d` if it doesn't exist yet. Requires fzf.
help() {
    local dir=/root/help.d
    local choice
    choice=$(ls "$dir" 2>/dev/null | sed 's/\.help$//' | fzf --prompt="project> " --height=~12 --reverse)
    [ -z "$choice" ] && return
    if [ -f "$dir/$choice.help" ]; then
        echo
        cat "$dir/$choice.help"
    else
        echo "No help file for '$choice' yet."
    fi
}
