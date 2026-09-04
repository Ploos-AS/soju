# Ploos-AS soju

Production-oriented OCI packaging for [soju](https://soju.im/), the IRC bouncer maintained at Codeberg.

> Upstream already publishes a container image. This repository is an independent Ploos-AS packaging project focused on reproducible source builds, explicit upstream pinning, non-root operation, multi-architecture GHCR releases, and supply-chain attestations. It is not a fork of soju.

## Image

```text
ghcr.io/ploos-as/soju
```

Target platforms:

- `linux/amd64`
- `linux/arm64`

## Upstream pin

The initial image is pinned to upstream commit:

```text
8bff925bd7b952babe085eedac6c5f9eb68e39c5
```

The active upstream repository is hosted on Codeberg. The historical GitHub mirror was archived in April 2026 and is used only as a verification mirror for this pinned commit.

## Quick start

```bash
mkdir -p data
sudo chown -R 1000:1000 data

docker compose up -d
```

The default container configuration listens on unencrypted IRC port `6667`. Put soju behind a TLS-terminating reverse proxy or provide your own `/etc/soju/config` with native TLS configuration before exposing it outside a trusted network.

Create the first administrator:

```bash
docker compose exec soju sojudb -config /etc/soju/config create-user <username> -admin
```

Restart soju after database changes made with `sojudb`.

## Persistence

Persistent state is stored in:

```text
/var/lib/soju
```

The container runs as UID/GID `1000:1000` (`soju`). Bind-mounted host directories must therefore be writable by that UID/GID.

## Configuration

A conservative default configuration is included at `/etc/soju/config`:

```text
db sqlite3 /var/lib/soju/main.db
listen irc://0.0.0.0:6667
```

To use your own configuration, mount it read-only:

```yaml
volumes:
  - ./config:/etc/soju/config:ro
  - ./data:/var/lib/soju
```

## Security model

The reference Compose setup:

- runs as an unprivileged user
- drops all Linux capabilities
- enables `no-new-privileges`
- does not mount the Docker socket
- does not use host networking
- persists only soju application data

## Releases

Tags matching `v*` publish semver aliases to GHCR and build both amd64 and arm64 images. Release builds include SBOM and provenance/attestation metadata.

## Upstream

- Project: https://codeberg.org/emersion/soju
- Website: https://soju.im/
- License: AGPL-3.0-only

soju is Copyright (C) the soju contributors. This repository contains independent container packaging around the unmodified upstream software.
