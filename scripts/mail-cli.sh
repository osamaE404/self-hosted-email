# Management shortcuts for this mail stack — add/remove mailboxes and
# aliases, check the queue, tail logs, without memorizing the docker
# compose exec incantations each time.
#
# Install: copy into ~/.bash_aliases on the server (or source it from your
# .bashrc), adjusting `dir` below if you cloned this repo somewhere other
# than the path shown.
mail() {
    local dir=/root/self-hosted-email
    case "$1" in
        add)
            [ -z "$2" ] && { echo "usage: mail add user@domain"; return 1; }
            (cd "$dir" && docker compose exec -it mailserver setup email add "$2")
            ;;
        del|remove)
            [ -z "$2" ] && { echo "usage: mail del user@domain"; return 1; }
            (cd "$dir" && docker compose exec mailserver setup email del -y "$2")
            ;;
        list)
            (cd "$dir" && docker compose exec mailserver setup email list)
            ;;
        password|passwd)
            [ -z "$2" ] && { echo "usage: mail password user@domain"; return 1; }
            (cd "$dir" && docker compose exec -it mailserver setup email update "$2")
            ;;
        alias-add)
            [ -z "$3" ] && { echo "usage: mail alias-add alias@domain target@domain"; return 1; }
            (cd "$dir" && docker compose exec mailserver setup alias add "$2" "$3")
            ;;
        alias-del)
            [ -z "$3" ] && { echo "usage: mail alias-del alias@domain target@domain"; return 1; }
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
        *)
            echo "usage: mail {add|del|list|password|alias-add|alias-del|alias-list|dkim|queue|status|logs|restart} [args]"
            ;;
    esac
}
