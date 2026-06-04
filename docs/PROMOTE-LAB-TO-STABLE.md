# Promote Lab → Stable

Lab builds (4-segment tags like `1.1.2.1`) ship with `<sparkle:channel>lab</sparkle:channel>`
in `appcast.xml`, so only Lab opt-ins receive them. Promoting to Stable means tagging the
same commit with a 3-segment tag (`1.1.2`) — CI strips the channel tag and every user
receives the update.

## TL;DR (one-liner)

```bash
cd /Users/charles/Documents/Tools\ Proj/ClashFX
./scripts/promote-to-stable.sh 1.1.2.1 1.1.2 --issues 75,104
```

The script handles preflight checks, tag push, CI watch, appcast verification, and
issue notifications. Confirm the prompts (or pass `--yes` to skip).

## What the script does

| Step | Action |
|------|--------|
| 1 | Verify gh active account = `mixc6763-prog` (switch if needed) |
| 2 | Verify working tree clean + local main = origin/main |
| 3 | Verify Lab release exists, is `prerelease=true`, and age ≥ 24h |
| 4 | Verify the Stable tag slot is free (no existing release) |
| 5 | Show the latest comment on each referenced issue (regression check) |
| 6 | Final confirm prompt |
| 7 | `git tag <stable> <main-HEAD>` + `git push origin <stable>` |
| 8 | Watch the CI run (`gh run watch --exit-status`) |
| 9 | Verify the new GitHub Release is `prerelease=false` |
| 10 | Fetch live appcast.xml, confirm new entry has no `<sparkle:channel>` |
| 11 | Post a Chinese promote-notice comment on each `--issues` issue |

## Prerequisites

- `gh` CLI logged in to `mixc6763-prog` (script auto-switches if not active)
- Local checkout of `Clash-FX/ClashFX` is on `main` with no uncommitted changes
- The Lab tag you're promoting from already exists as a published GitHub Release

## Pre-flight observations (recommended before running)

1. **Lab age**: 24-48h is the sweet spot. Less than 24h triggers a confirm prompt.
2. **Issue activity**: open the issues fixed in the Lab build. Look for any new
   comment from the original reporter saying the problem persists. The script
   prints the latest comment for you, but a real reread is wiser.
3. **GitHub Discussions / new issues**: check if any new issues were opened
   that look related to the Lab changes (menu behavior, bypass toggle, etc.).
4. **Crash spike**: if you have App Center / Sentry, skim it.

## Examples

```bash
./scripts/promote-to-stable.sh 1.1.2.1 1.1.2 --issues 75,104
./scripts/promote-to-stable.sh 1.1.3.2 1.1.3 --yes
./scripts/promote-to-stable.sh 1.2.0.5 1.2.0 --issues 200,201 --yes
```

## Manual steps (if you ever need to bypass the script)

```bash
gh auth switch -u mixc6763-prog
git fetch origin main && git checkout main && git pull --ff-only
git tag 1.1.2 HEAD
git push origin 1.1.2
gh run watch --exit-status $(gh run list -R Clash-FX/ClashFX --workflow=main.yml --limit 1 --json databaseId --jq '.[0].databaseId') -R Clash-FX/ClashFX
gh release view 1.1.2 -R Clash-FX/ClashFX --json isPrerelease
curl -sS https://clash-fx.github.io/ClashFX/appcast.xml | grep -A 20 '1.1.2'
```

## Rollback (if Stable build turns out broken)

The cleanest path is **forward, not backward**:

1. Push a fix commit to `main`
2. Tag a new Lab build (e.g. `1.1.3.1`) to validate the fix
3. Promote that to Stable (`1.1.3`)

Stable users on the broken `1.1.2` will be auto-prompted to upgrade to `1.1.3`
within ~24h via Sparkle.

If a fix isn't ready and you need users to **stop** picking up the broken build:

1. Edit `docs/appcast.xml` on `main` to remove the offending `<item>` for the
   broken Stable release (keep the prior Stable release as the latest).
2. Commit + push. GitHub Pages republishes within ~1 min.
3. Users who already updated stay on the broken version, but no new users will
   receive it via Sparkle. Existing users will need the fix release to recover.

Do **not** delete the GitHub Release — keep it for traceability. Only edit the
appcast feed.

## Why this works

- CI in [`.github/workflows/main.yml`](../.github/workflows/main.yml) detects the
  tag segment count: 3 segments → `RELEASE_CHANNEL=stable`, 4 segments → `lab`.
- The appcast.xml updater step adds `<sparkle:channel>lab</sparkle:channel>` only
  when `channel == "lab"`.
- Sparkle on the client filters appcast items by channel: Stable users skip any
  item that declares a channel; Lab users accept items with channel="lab".
- Promoting from Lab to Stable means re-tagging the same code with a 3-segment
  tag. Same source, new release, no channel tag, every user receives it.

## Notes on Sparkle versioning

The numeric `<sparkle:version>` is computed by CI as:

```
major * 10^9 + minor * 10^6 + patch * 10^3 + lab
```

| Tag       | Numeric     |
|-----------|-------------|
| `1.1.1`   | `1001001000` |
| `1.1.2.1` | `1001002001` |
| `1.1.2`   | `1001002000` |

A Lab build always has a higher numeric version than the Stable of the same
patch — which is what you want. Stable users on `1.1.1` see Stable `1.1.2`
(`1001002000`) and upgrade. Lab users on `1.1.2.1` (`1001002001`) do **not**
"downgrade" to `1.1.2` (`1001002000`) because Sparkle won't downgrade across
appcast items; instead they wait for the next Lab build (e.g. `1.1.3.1` at
`1001003001`).
