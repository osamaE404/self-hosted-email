# Hosting more than one domain

This mail server isn't limited to one domain — you can add mailboxes on
any domain that points its MX record here, all on the same running stack.

## Adding a domain

1. Point its DNS at this server — MX, SPF, and DMARC are all per-domain
   (they don't inherit from a parent domain to a subdomain, or between
   unrelated domains), so each new domain needs its own copy. See
   [`dns-records.md`](dns-records.md) for the record set — same pattern,
   substitute the new domain. No new A record or certificate is needed if
   you're adding a *subdomain* of the main domain (`aser.example.com`
   under `example.com`, say) — MX just points at the existing mail
   hostname either way.
2. Create the mailbox: `email add someone@newdomain.com`. docker-mailserver
   picks up the new domain automatically from the address — no separate
   "register this domain" step.
3. Generate its DKIM key **with the domain named explicitly**:
   `email dkim newdomain.com`.

## The DKIM gotcha

`email dkim` with no argument does **not** generate keys for every domain
that has a mailbox — it only targets the server's own primary domain
(the one in `MAIL_HOSTNAME`/`MAIL_DOMAIN`). Running it bare after adding a
second domain will just try to regenerate the *first* domain's key again
and fail with "not overwriting existing files." Always pass the domain
for anything beyond the first: `email dkim newdomain.com`.

## A real gotcha hit while adding a second domain

Generating a DKIM key for a new domain restarts Rspamd (spam filtering +
DKIM signing) to pick up the new key. That restart can end with Rspamd
stuck in a `STOPPING` state rather than actually coming back up — the
command's own output looks like a boilerplate warning
("Could not restart Rspamd via Supervisord") and easy to skim past, but
it means spam filtering and DKIM signing are down for the *whole*
server, both domains, not just the new one, until it's manually kicked:

```
docker compose exec mailserver supervisorctl status rspamd
# if it shows anything other than RUNNING:
docker compose exec mailserver supervisorctl restart rspamd
```

Worth checking this every time after `email dkim`, not just trusting the
command's exit output.
