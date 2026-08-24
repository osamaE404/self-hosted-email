# Guaranteeing a display name server-side

A mail client's own "Your Name" setting is easy to forget on a new device
or client, and there's no way to check every client is configured
correctly ahead of time. `email display-name <addr> "Name"` instead
rewrites the `From:` header at the server, so the name shown to recipients
is guaranteed regardless of what (or whether) any given client sends.

## How it works

It's a Postfix `header_checks` rule (a `pcre:` table doing a `REPLACE`)
matched against the message's `From:` header during the `cleanup` stage —
every message that enters the queue passes through this, whether it came
from an authenticated client (Thunderbird, a phone's mail app) or was
submitted locally. The rule lives in
`docker-data/dms/config/display-names.pcre`, one line per address; `email
display-name` manages that file for you (add/update/remove a line,
idempotently) rather than needing to hand-edit it.

## Two gotchas that cost real debugging time

**1. The first display name set on a box needs a full container
recreate, not just a restart or reload.** docker-mailserver only merges
`docker-data/dms/config/postfix-main.cf` into the live Postfix config as
part of its first-boot setup sequence — a plain `docker compose restart`
reuses the same container instance and skips that step entirely, so the
new `header_checks` parameter silently never takes effect. `email
display-name` handles this automatically: it checks whether
`header_checks` is already set, and only recreates the container
(`docker compose up -d --force-recreate mailserver`) the first time;
every subsequent name change is a plain `postfix reload`. Mailbox data
lives in separate bind-mounted volumes, so recreating the container is
safe and doesn't touch it.

**2. Testing this with `sendmail`/`mail` on the command line will make it
look broken even when it isn't.** Postfix's default config exempts
locally-submitted mail (the `pickup` service, used by the `sendmail` CLI)
from header/body checks via `-o receive_override_options=no_header_body_checks`
in `master.cf` — this is the same category of gotcha as `non_smtpd_milters`
being empty by default (see the DKIM note in the main README): mail
submitted locally on the box bypasses checks meant for real client
traffic. A real test needs an authenticated SMTP submission (an actual
client, or `swaks`/similar with `--auth`) — a `sendmail`-based test will
show the *unmodified* header and can look like the feature failed when it
didn't.
