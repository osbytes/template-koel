# Railway template wiring

Publish this as a Railway template named `koel` (not `template-koel`).

Railway does not deploy `docker-compose.yml` directly. Recreate its topology in
the template composer with services named exactly `app` and `postgres`.

Only **`app`** should be public. Postgres stays private.

**Template icon:** upload `assets/logo.svg` when publishing.

## Application services

Use `https://github.com/osbytes/template-koel` as the source for `app`.
Set the service root directory as shown; its local `railway.toml` sets the
Dockerfile and healthcheck.

### app

- Root directory: `/services/app`
- Public networking: enabled (this is the only URL users open)
- Recommended memory: at least 1 GB (scanning / ffmpeg can spike)
- Variables:

```text
APP_NAME=Koel  # Display name
APP_ENV=production  # Laravel environment
APP_DEBUG=false  # Keep false on public Internet
APP_KEY=  # Optional; empty auto-generates on first boot and persists under the /data volume — do not rotate after first deploy if set
APP_URL=https://${{RAILWAY_PUBLIC_DOMAIN}}  # Public HTTPS origin Koel should generate links for
FORCE_HTTPS=true  # Trust Railway TLS termination
DB_CONNECTION=pgsql  # Must be pgsql for this template's Postgres service
DB_HOST=${{postgres.RAILWAY_PRIVATE_DOMAIN}}  # Postgres private DNS — not the public URL
DB_PORT=5432  # Postgres port
DB_DATABASE=${{postgres.POSTGRES_DB}}  # Database name from postgres service
DB_USERNAME=${{postgres.POSTGRES_USER}}  # Database user from postgres service
DB_PASSWORD=${{postgres.POSTGRES_PASSWORD}}  # Database password from postgres service
MEDIA_PATH=/data/music  # Music library path inside the consolidated /data volume
STREAMING_METHOD=x-sendfile  # Apache x-sendfile; keep for efficient streaming
MEMORY_LIMIT=  # Optional scan memory limit in MB; leave empty for PHP default
LASTFM_API_KEY=  # Optional Last.fm API key
LASTFM_API_SECRET=  # Optional Last.fm API secret
SPOTIFY_CLIENT_ID=  # Optional Spotify client id for artwork
SPOTIFY_CLIENT_SECRET=  # Optional Spotify client secret
```

Keep the public domain target port at `80` (image Apache default).

Volume (one per service —
https://station.railway.com/feedback/multiple-volumes-per-service-7ce57788):

| Mount path | Purpose |
|------------|---------|
| `/data` | Consolidated persistence: `music/`, `images/`, `search-indexes/`, `.app_key` |

Upstream Compose mounts three separate volumes. This template merges them under
`/data` via the wrapper entrypoint so Railway's one-volume limit still covers
library, art, search indexes, and `APP_KEY`.

Healthcheck path: `/sw.js` (timeout 300s — first boot runs `koel:init` /
migrations).

## Data services

### postgres

- Image: `postgres:16`
- Public networking: disabled
- Volume: mount at `/var/lib/postgresql/data`
- Variables:

```text
POSTGRES_DB=koel  # Database name
POSTGRES_USER=koel  # Database user
POSTGRES_PASSWORD=${{secret(32)}}  # Random DB password; keep in sync with app DB_* refs
```

## Auth notes

- Open the **app** URL only.
- First `koel:init` creates default admin **`admin@koel.dev` / `KoelIsCool`**.
  Change the password immediately in the UI (or `php artisan koel:admin:change-password`).
- Registration of additional users is controlled in Koel settings after login.

## Deployment notes

- Keep both services in one Railway environment so reference variables and
  private DNS resolve correctly.
- Prefer Postgres over the MariaDB compose sibling — simpler on Railway and
  matches published `phanan/koel` `pgsql` support.
- Marketplace **Description**: paste `docs/description.md` into the template
  Description field when publishing.
- First boot can take 1–2 minutes while migrations run; wait for `/sw.js`.
- After deploy: open the public URL → log in with the default admin → change
  password → upload or sync music into `/data/music` (or use the UI library
  settings if pointing elsewhere under that volume).
- Image pin: Docker Hub `phanan/koel:9.11.0` (upstream release `v9.11.0`).
  GitHub Releases keep the `v` prefix; Docker Hub semver tags do not.

## Troubleshooting

| Symptom | Likely cause |
|---------|--------------|
| App crash-loops on DB | Postgres not ready / wrong `DB_*` refs |
| Blank / mixed-content over HTTPS | Missing `FORCE_HTTPS=true` or wrong `APP_URL` |
| Library empty after redeploy | Volume not mounted at `/data`, or files not under `/data/music` |
| Login / session broken after redeploy | `APP_KEY` rotated; restore previous key or wipe DB and re-init |
| Init skipped / no admin | Wrapper failed to write `.env`; check deploy logs for `koel-init` |
| Slow scans / OOM | Raise memory; set `MEMORY_LIMIT` (MB) |
