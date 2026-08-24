# Management shortcut for this mail stack — add/remove mailboxes, set a
# guaranteed display name per mailbox, manage aliases, check the queue,
# tail logs, without memorizing the docker compose exec incantations each
# time. Renamed from an earlier `mail` function to avoid colliding with
# the system mailx/mail binary.
#
# Install: copy into ~/.bash_aliases on the server (or source it from your
# .bashrc), adjusting `dir` below if you cloned this repo somewhere other
# than the path shown. Pair with scripts/help-launcher.sh if the box runs
# more than one project and you want a single `help` entry point across
# all of them.
email() {
    local dir=/root/self-hosted-email
    case "$1" in
        add)
            [ -z "$2" ] && { echo "usage: email add user@domain"; return 1; }
            (cd "$dir" && docker compose exec -it mailserver setup email add "$2") || return 1
            read -rp "Display name for $2 (shown to recipients, blank to skip): " dname
            [ -n "$dname" ] && email display-name "$2" "$dname"
            ;;
        del|remove)
            [ -z "$2" ] && { echo "usage: email del user@domain"; return 1; }
            (cd "$dir" && docker compose exec mailserver setup email del -y "$2")
            local pcre="$dir/docker-data/dms/config/display-names.pcre"
            [ -f "$pcre" ] && { grep -vF "<$2>" "$pcre" > "$pcre.tmp"; mv "$pcre.tmp" "$pcre"; }
            ;;
        list)
            local pcre="$dir/docker-data/dms/config/display-names.pcre"
            (cd "$dir" && docker compose exec mailserver setup email list) | while IFS= read -r line; do
                local addr; local dname=""
                addr=$(echo "$line" | grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+' | head -1)
                if [ -n "$addr" ] && [ -f "$pcre" ]; then
                    dname=$(grep -F "<$addr>" "$pcre" | sed -n 's/.*REPLACE From: "\([^"]*\)".*/\1/p' | head -1)
                fi
                if [ -n "$dname" ]; then
                    echo "$line   name: \"$dname\""
                else
                    echo "$line"
                fi
            done
            ;;
        password|passwd)
            [ -z "$2" ] && { echo "usage: email password user@domain"; return 1; }
            (cd "$dir" && docker compose exec -it mailserver setup email update "$2")
            ;;
        display-name|edit)
            [ -z "$3" ] && { echo 'usage: email display-name user@domain "Full Name"'; return 1; }
            local addr="$2" name="$3"
            local cfgdir="$dir/docker-data/dms/config"
            local pcre="$cfgdir/display-names.pcre"
            local maincf="$cfgdir/postfix-main.cf"
            mkdir -p "$cfgdir"
            touch "$pcre" "$maincf"
            grep -vF "<$addr>" "$pcre" > "$pcre.tmp" 2>/dev/null
            mv "$pcre.tmp" "$pcre"
            local esc_addr
            esc_addr=$(printf '%s' "$addr" | sed 's/\./\\./g')
            echo "/^From:.*${esc_addr}/i  REPLACE From: \"$name\" <$addr>" >> "$pcre"
            if grep -q "^header_checks" "$maincf" 2>/dev/null; then
                (cd "$dir" && docker compose exec mailserver postfix reload) >/dev/null 2>&1
            else
                echo "header_checks = pcre:/tmp/docker-mailserver/display-names.pcre" >> "$maincf"
                echo "First display name on this box -- applying (one-time container recreate)..."
                (cd "$dir" && docker compose up -d --force-recreate mailserver)
            fi
            echo "Display name for $addr set to: $name"
            ;;
        alias-add)
            [ -z "$3" ] && { echo "usage: email alias-add alias@domain target@domain"; return 1; }
            (cd "$dir" && docker compose exec mailserver setup alias add "$2" "$3")
            ;;
        alias-del)
            [ -z "$3" ] && { echo "usage: email alias-del alias@domain target@domain"; return 1; }
            (cd "$dir" && docker compose exec mailserver setup alias del "$2" "$3")
            ;;
        alias-list)
            (cd "$dir" && docker compose exec mailserver setup alias list)
            ;;
        dkim)
            (cd "$dir" && docker compose exec mailserver setup config dkim)
            ;;
        queue)
            (cd "$dir" && docker compose exec mailserver postqueue -p)
            ;;
        status)
            (cd "$dir" && docker compose ps)
            ;;
        logs)
            (cd "$dir" && docker compose logs -f --tail 100 mailserver)
            ;;
        restart)
            (cd "$dir" && docker compose restart mailserver)
            ;;
        -h|--help|help|"")
            [ -f /root/help.d/email.help ] && cat /root/help.d/email.help || \
              echo "usage: email {add|del|list|password|display-name|alias-add|alias-del|alias-list|dkim|queue|status|logs|restart|-h}"
            ;;
        *)
            echo "usage: email {add|del|list|password|display-name|alias-add|alias-del|alias-list|dkim|queue|status|logs|restart|-h}"
            ;;
    esac
}
