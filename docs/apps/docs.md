# Documentation Server Installation

MkDocs Material server for browsing RagnaLab documentation.

**URL:** https://docs.ragnalab.xyz

---

## Prerequisites

- Traefik running (see [Traefik](../infrastructure/traefik.md))

---

## Installation

### 1. Deploy

```bash
docker compose -f apps/docs/docker-compose.yml up -d
```

### 2. Verify

```bash
curl -I https://docs.ragnalab.xyz
```

Open https://docs.ragnalab.xyz in your browser.

---

## Manual Steps

**None** - the docs server is fully automated.

---

## How It Works

MkDocs Material serves the `docs/` folder as a static site with:
- Search functionality
- Dark/light mode toggle
- Mobile responsive design
- Syntax highlighting

The documentation is mounted read-only from the repository root.

---

## Local Development

For editing docs locally without deploying:

```bash
docker run --rm -it -p 8000:8000 -v $(pwd):/docs squidfunk/mkdocs-material serve --dev-addr=0.0.0.0:8000
```

Then open http://localhost:8000

---

## Building Static Site

To generate static HTML (for GitHub Pages, etc.):

```bash
docker run --rm -v $(pwd):/docs squidfunk/mkdocs-material build
```

Output goes to `site/` directory.

---

## Files

| File | Purpose |
|------|---------|
| `apps/docs/docker-compose.yml` | Container configuration |
| `mkdocs.yml` | MkDocs configuration |
| `docs/` | Documentation source files |

---

## Troubleshooting

### Changes not appearing

MkDocs serves files live - changes should appear on refresh. If not:

```bash
docker restart docs
```

### 404 errors

Check `mkdocs.yml` nav section matches actual file paths in `docs/`.
