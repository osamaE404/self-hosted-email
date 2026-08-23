# Getting a certificate when Caddy already owns ports 80/443

If another service on the box already runs Caddy bound to 80/443 for its
own domain, this mail stack shouldn't run a second ACME client competing
for those ports. Instead, let the existing Caddy issue a certificate for
`mail.example.com` too, and hand that certificate to this stack.

## 1. Add a site block to the existing Caddy, without editing its config file

If the existing `Caddyfile` is tracked in git, editing it directly creates
a real hazard: the *next* deploy of that project (`git pull && ... up -d`)
either refuses to pull because of the local change, or resets the tree and
silently reverts it — and a certificate quietly stops renewing weeks later
with nobody watching.

The clean fix is an import-glob pattern, so a new site lives in its own
untracked file instead of an edit to a shared one:

```caddyfile
# In the existing Caddyfile, once:
import /etc/caddy/caddy.d/*.caddy
```

Bind-mount a `caddy.d/` directory into that Caddy container, gitignore
`caddy.d/*.caddy` in that project's repo (keep the directory itself tracked,
e.g. via a `.gitkeep` or README, so a fresh clone still has a mount target).
Then drop this repo's `examples/mail.caddy.example` in as `caddy.d/mail.caddy`
(with the real hostname substituted in), and apply it:

```sh
docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile
docker compose exec caddy caddy reload   --config /etc/caddy/Caddyfile
```

**Reload only — never `restart` or `down`** the shared Caddy container for
this. A restart drops in-flight connections to whatever else that Caddy is
serving; `down` stops every other service in that same compose project too,
if it's a shared compose file. `reload` re-reads config with zero drops.

Point the mail hostname's `A` record at the box *before* doing this, or the
certificate order fails and retries in the log.

## 2. Mount the certificate into this stack, narrowly

Caddy's certificate storage sits inside its own data directory, which may
also hold state belonging to whatever else that Caddy serves — don't mount
that whole directory into an unrelated container. Mount only the specific
certificate's leaf directory, read-only:

```yaml
volumes:
  - /path/to/caddy/data/caddy/certificates/acme-v02.api.letsencrypt.org-directory/mail.example.com:/certs:ro
```

Two things about that path:

1. **It doesn't exist until the certificate has actually been issued.**
   Start this mail stack only *after* confirming issuance succeeded, or
   Docker silently creates an empty directory and the mail services start
   with no certificate.
2. **The `acme-v02...` segment is the issuer name.** If Caddy ever falls
   back to a different ACME issuer, the path changes and the mount goes
   stale — pointing at a directory that no longer receives renewals. Worth
   checking first if a certificate ever expires unexpectedly.

Then point `TLS_CERT_PATH`/`TLS_KEY_PATH` in `.env` at the two files inside
that mounted leaf directory (`fullchain.pem` / whichever key file Caddy
wrote there).
