# jellyfin-tizen (improved)

[![GitHub Repo](https://img.shields.io/badge/GitHub-eskogh%2Fjellyfin--tizen-black?logo=github)](https://github.com/eskogh/jellyfin-tizen)
[![Docker Pulls](https://img.shields.io/docker/pulls/erikskogh/jellyfin-tizen)](https://hub.docker.com/r/erikskogh/jellyfin-tizen)
[![Image Size](https://img.shields.io/docker/image-size/erikskogh/jellyfin-tizen/latest)](https://hub.docker.com/r/erikskogh/jellyfin-tizen)

Dockerized helper to build and sideload the **Jellyfin** Tizen app onto Samsung TVs (Developer Mode).

**Docker Hub:** https://hub.docker.com/r/erikskogh/jellyfin-tizen

## Quickstart

```bash
# 1) Build image
docker build -t erikskogh/jellyfin-tizen:latest .

# 2) Run container with a persistent home (keeps certs)
docker run --rm -it \
  -v jellyfin-tizen-home:/home/jellyfin \
  --name jf-tizen erikskogh/jellyfin-tizen:latest

# Inside the container:
cp /jellyfin-tizen/.env.example ~/.env
tizen-jellyfin certify
tizen-jellyfin build
tizen-jellyfin send
```

> Enable **Developer Mode** on your TV (Apps screen, type `1-2-3-4-5`), and set the **host IP** (Docker host, not the container IP).

## Makefile shortcuts

```bash
make build TAG=latest
make run
make push TAG=latest
```

## Environment (.env)

```
TIZEN_NAME=Your Name
TIZEN_EMAIL=name@example.com
TIZEN_COMPANY=Your Org
TIZEN_CITY=City
TIZEN_STATE=State
TIZEN_COUNTRY=SE
TIZEN_PASSWORD=1234
TIZEN_IP=192.168.1.50
```

## Commands

- `tizen-jellyfin certify` – creates an author certificate + security profile.
- `tizen-jellyfin build` – builds and packages `Jellyfin.wgt`.
- `tizen-jellyfin send` – connects via `sdb` and installs the widget to your TV.
- `tizen-jellyfin all` – runs certify → build → send.

## License
MIT — see [LICENSE](./LICENSE).

## Links
- Docker Hub: https://hub.docker.com/r/erikskogh/jellyfin-tizen
- Source: https://github.com/eskogh/jellyfin-tizen
