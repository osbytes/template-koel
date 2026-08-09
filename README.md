# Koel on Railway

Railway template scaffolding for [Koel](https://github.com/koel/koel), a
personal music streaming server. The published Railway marketplace name is
**koel**.

Based on the upstream [koel/docker](https://github.com/koel/docker) Compose
stack (PostgreSQL variant), with a thin wrapper so Railway's one-volume limit
still covers music, artwork, search indexes, and `APP_KEY`.

The template runs Koel as two Railway services:

- `app` — Koel web UI + Apache (public)
- `postgres` — application database (private)

## Railway template

Follow [`docs/railway-wiring.md`](docs/railway-wiring.md) when creating or
updating the marketplace template. It contains the exact service names,
reference variables, generated secrets, ports, healthchecks, and volume mounts.

Paste [`docs/description.md`](docs/description.md) into the Railway template
**Description** field when publishing.

Only the **app** URL should be opened in a browser. Postgres stays on Railway
private networking.

The wrapper currently tracks Koel `9.11.0` (Docker Hub tag for upstream release
`v9.11.0`).

## Run locally

1. Copy `.env.example` to `.env`.
2. Optionally set `APP_KEY` (`docker run --rm phanan/koel:9.11.0 php artisan key:generate --show`).
   Leave empty to auto-generate on first boot (stored under the `/data` volume).
3. Start the stack:

```bash
docker compose up --build
```

Open `http://localhost:8080`. Sign in with the default admin
`admin@koel.dev` / `KoelIsCool`, then change the password immediately.

Put audio files under the `koel-data` volume at `/data/music` (or sync via the
UI) and trigger a library scan.

## Updating Koel

1. Bump the image tag in `services/app/Dockerfile` to the new Docker Hub semver
   (GitHub release `vX.Y.Z` → image tag `X.Y.Z`).
2. Diff upstream
   [docker-compose.postgres.yml](https://github.com/koel/docker/blob/master/docker-compose.postgres.yml)
   and the [koel/docker README](https://github.com/koel/docker) for env/volume
   changes and port them here.
3. Run `docker compose config` and smoke-test `/sw.js`, admin login, a small
   library scan, and playback.

`upstream-check.yml` opens a version-bump PR weekly. Koel's Docker Hub tags omit
the leading `v` from GitHub releases — strip it if a bot PR rewrites `FROM` to a
non-existent `v*` tag before merging.

## License

This repository contains deployment configuration only. Koel is distributed
under MIT; see the
[upstream license](https://github.com/koel/koel/blob/master/LICENSE).

Community-maintained Railway packaging — not an official Koel project.
