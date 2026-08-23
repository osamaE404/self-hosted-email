# self-hosted-email

A minimal, low-resource self-hosted mail server: [docker-mailserver](https://github.com/docker-mailserver/docker-mailserver)
(Postfix + Dovecot + Rspamd) behind a single `docker-compose.yml`, designed
to run on a small VPS (~1GB RAM footprint) and to coexist peacefully with
other services already on the same box.

Standard IMAP/SMTP, so any mail client works — Thunderbird, the Gmail app
(added as a separate account, not merged into your Gmail inbox — Google
doesn't support hosting a third-party domain inside Gmail itself for free),
Apple Mail, K-9, etc.

## Why this stack, not Mailcow/Mailu

- **Mailcow** officially wants 6GB+ RAM. On a smaller VPS it'll run poorly
  or get OOM-killed.
- **Mailu** is modular (separate containers per component) with meaningfully
  more overhead for a single mailbox.
- **docker-mailserver** is one container, well-documented, and comfortable
  in ~1GB RAM once ClamAV is left off (see below). No webmail UI included —
  if you're only ever reading mail through a real client, you don't need one.

ClamAV is deliberately disabled (`ENABLE_CLAMAV=0`) — it alone wants close
to 1GB of RAM, which a small VPS usually can't spare. Rspamd's spam
filtering stays on regardless.

## Prerequisites

- A domain you can add DNS records to.
- A server with Docker + Docker Compose installed, with a static public IP.
- A way to get a TLS certificate for the mail hostname. If you already run
  Caddy on that box for something else (and it owns ports 80/443), see
  [`docs/caddy-integration.md`](docs/caddy-integration.md) for getting a
  certificate without a second ACME client or a port conflict. If the box
  is otherwise free, point any ACME client (Caddy, certbot) at the mail
  hostname and skip that doc.
- Outbound port 25 open. Most cloud/VPS providers block it by default on
  new servers as an anti-spam measure — check with your provider; it's
  usually a quick support ticket, but only they can lift it.

## Quick start

```sh
cp .env.example .env
# edit .env: set MAIL_HOSTNAME, MAIL_DOMAIN, ADMIN_EMAIL, and the two
# TLS_*_PATH values (see Prerequisites above for where the cert comes from)

docker compose up -d

./scripts/setup.sh dkim
# prints the DKIM public key — add it as a DNS TXT record
# (see docs/dns-records.md for the full record set: MX, SPF, DKIM, DMARC)

./scripts/setup.sh add-account you@yourdomain.com
# prompts for a password interactively — never pass it on the command line
# or store it in this repo
```

Then add the DNS records in [`docs/dns-records.md`](docs/dns-records.md),
including the DKIM value the setup script just printed, and set your
provider's reverse-DNS (PTR) record for the box to your mail hostname —
also covered in that doc. Both matter for deliverability, especially to
Gmail.

## Client setup

- **Thunderbird**: Account Settings → Add Mail Account → enter the address,
  then manually configure IMAP (`MAIL_HOSTNAME`, port 993, SSL/TLS) and
  SMTP (port 587, STARTTLS), authenticating with the mailbox's own
  credentials.
- **Gmail app**: Settings → Add account → Other (IMAP) — same server
  details as above. This adds it as its own inbox alongside your Gmail
  account; Gmail's free tier can't merge a third-party domain into the
  primary inbox (that needs Google Workspace).

## Coexisting with other services on the same box

This stack listens only on 25/465/587/993/143 — it doesn't touch 80/443 or
any port another service already uses. The one shared resource, if another
service already runs the box's Caddy, is that Caddy instance itself (for
the certificate); see `docs/caddy-integration.md` for doing that without
risking the other service's config or uptime.

## Verifying it works

See the "Verifying propagation" section of
[`docs/dns-records.md`](docs/dns-records.md) for DNS/blacklist/deliverability
checks before pointing real traffic at it.

## Repo layout

```
docker-compose.yml       the mail stack
.env.example              template for the real, gitignored .env
scripts/setup.sh          wrapper for DKIM generation + adding mailboxes
docs/dns-records.md        every DNS record needed, with placeholders
docs/caddy-integration.md  sharing an existing Caddy instance's ports/certs
examples/mail.caddy.example  the Caddy site block to drop in for the cert
```
