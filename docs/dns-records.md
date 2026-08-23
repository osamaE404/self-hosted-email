# DNS records

Add these at your registrar/DNS host. `example.com` / `203.0.113.10` are
placeholders — substitute your own domain and server IP throughout.

| Type | Name | Value | TTL |
|---|---|---|---|
| A | `mail.example.com` | `203.0.113.10` | 300s while testing |
| MX | `example.com` | `mail.example.com` (priority 10) | 300s |
| TXT (SPF) | `example.com` | `v=spf1 mx ~all` | 300s |
| TXT (DKIM) | `mail._domainkey.example.com` | printed by `./scripts/setup.sh dkim` | 300s |
| TXT (DMARC) | `_dmarc.example.com` | `v=DMARC1; p=quarantine; rua=mailto:postmaster@example.com` | 300s |
| CAA (recommended) | `example.com` | `0 issue "letsencrypt.org"` | 3600s |

A low TTL (300s) during setup means a mistake propagates and gets fixed in
minutes rather than being stuck behind a stale cache for an hour+. At a
single mailbox's query volume there's no real cost to leaving it there
permanently.

## Reverse DNS (PTR)

Mail deliverability — especially to Gmail — depends on the server's PTR
record resolving back to `mail.example.com`. This is set with your **VPS
provider** (not your domain's DNS host) and is usually self-service in
their control panel. Skipping this is one of the most common reasons
self-hosted mail lands in spam or gets rejected outright.

## Outbound port 25

Most cloud/VPS providers block outbound port 25 by default on new servers,
as an anti-spam measure — inbound (other servers sending mail *to* you)
is unaffected, but nothing you send out will leave the box until it's
lifted. This is usually a quick support ticket with your provider, tied to
your account, and can't be done by a script.

## Verifying propagation

```sh
dig MX example.com
dig TXT mail._domainkey.example.com
dig TXT _dmarc.example.com
```

Before relying on the server, check its IP isn't already on a blacklist
(a fresh IP from a large provider sometimes inherits one from a previous
tenant) — any of the free blacklist-lookup tools will do. Then send a test
message to a mail deliverability tester to confirm SPF/DKIM/DMARC all pass
before pointing real traffic at it.
