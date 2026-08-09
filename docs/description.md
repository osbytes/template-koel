# Deploy and Host Koel on Railway

Koel is a personal music streaming server. Upload or sync a library, browse
artists/albums/playlists, and stream from the web UI (and companion apps).

## About Hosting Koel

This template runs Koel with PostgreSQL. Only the app is public; the database
stays on private networking. A single volume at `/data` holds the music
library, artwork, search indexes, and the persisted `APP_KEY` (Railway allows
one volume per service). First boot runs `koel:init` / migrations and may take
a minute before `/sw.js` is ready.

Default admin after first boot: `admin@koel.dev` / `KoelIsCool` — change it
immediately.

## Common Use Cases

- Personal always-on music library with browser / mobile clients
- Shared household streaming with playlists and queue
- Self-hosted alternative to cloud music lock-in

## Dependencies for Koel Hosting

- Koel app (`phanan/koel`)
- PostgreSQL 16

### Deployment Dependencies

- Upstream project: https://github.com/koel/koel
- Docker image / Compose: https://github.com/koel/docker
- Product docs: https://docs.koel.dev/
- Docker Hub: https://hub.docker.com/r/phanan/koel

### Implementation Details

- Public entry: app on port `80`, healthcheck `/sw.js`
- Wrapper entrypoint writes `.env` (required by `koel-init`) and consolidates
  upstream's three volumes under `/data`
- Optional Last.fm / Spotify keys for metadata and artwork

## Why Deploy Koel on Railway?

<!-- Recommended: Keep this section as shown below -->
Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Koel on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
<!-- End recommended section -->
