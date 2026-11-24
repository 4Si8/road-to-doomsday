# Road to Doomsday: Nuvio addon

A catalog-only Stremio/Nuvio addon with three rows, each in watch order:

| Catalog | Items | What's in it |
|---------|-------|--------------|
| Road to Doomsday: Full Order | 28 | Everything in [WATCH_ORDER.md](WATCH_ORDER.md) |
| Road to Doomsday: Essentials | 18 | ⭐ titles only |
| Road to Doomsday: Speedrun | 9 | The ~21-hour short path |

Items use real IMDb IDs, so Nuvio's metadata and stream addons work on them as normal. Each card is numbered (`9. Avengers: Endgame (Encore)`), and the description explains why the title matters for Doomsday.

The addon is plain static JSON and needs no runtime. It's built with PowerShell, which Windows already has.

## Install

In Nuvio, go to **Settings → Addons → Add Addon** and paste:

```
https://4si8.github.io/road-to-doomsday/manifest.json
```

The addon is hosted on GitHub Pages and redeploys on every push to `main`.

## Files

- `data/watchorder.json`: the list. **Edit this file**, then rebuild.
- `build.ps1`: generates `addon/` (`manifest.json` and `catalog/movie/*.json`)
- `serve.ps1`: local server with CORS, for testing in Nuvio on this PC
- `addon/`: the built addon. This folder is the one you host.

## Build and run locally

```powershell
powershell -ExecutionPolicy Bypass -File build.ps1
powershell -ExecutionPolicy Bypass -File serve.ps1      # port 7000
```

In Nuvio, go to **Settings → Addons → Add Addon** and paste:

```
http://127.0.0.1:7000/manifest.json
```

The local server only works while it's running, and only for Nuvio on this PC.

## Host it (phone, TV, other devices)

Upload the **contents** of `addon/` to any static HTTPS host. It needs to serve `.json` files with `Access-Control-Allow-Origin: *`, which both of these do:

- **GitHub Pages:** push `addon/` to a repo and enable Pages. The addon URL is then `https://<user>.github.io/<repo>/manifest.json`.
- **Netlify / Cloudflare Pages:** drag and drop the `addon/` folder.

## Updating the list

Edit `data/watchorder.json` and run `build.ps1`. If you've hosted the addon, re-upload `addon/` and bump `version` in `build.ps1`. Fields:

- `id`: IMDb ID
- `type`: `movie` or `series`
- `tier`: `essential`, `recommended` or `optional`
- `speedrun`: `true` / `false`
- `runtime`
- `note`

Order in the file is the watch order.

## Notes

- Each catalog is declared as type `movie` but contains series items too, which the Stremio protocol allows because every item carries its own `type`. If your Nuvio build doesn't open the shows (Loki, WandaVision, Falcon and the Winter Soldier, Hawkeye, VisionQuest) properly from these rows, they need to be split into a separate `series` catalog.
- Loki appears once, at Season 1's position. Its card says to watch Season 2 after Quantumania.
- Endgame Encore uses the original Endgame ID (`tt4154796`), because Encore doesn't have a separate IMDb entry.
- Posters come from metahub.space (Stremio's image CDN).
