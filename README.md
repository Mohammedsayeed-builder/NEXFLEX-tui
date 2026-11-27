<div align="center">

# NEXFLEX

**Terminal interface to find, download, and stream movies, TV shows, and live TV using local media players.**

Created by **Mohammed Sayeed**.

[ English ](README.md) • [ বাংলা ](README_BN.md) • [ हिन्दी ](README_HI.md) • [ Español ](README_ES.md)

[![CI](https://img.shields.io/github/actions/workflow/status/Mohammedsayeed-builder/NEXFLEX-tui/ci.yml?branch=main&label=CI&logo=github&style=flat)](https://github.com/Mohammedsayeed-builder/NEXFLEX-tui/actions/workflows/ci.yml)
[![crates.io](https://img.shields.io/crates/v/nexflex.svg?logo=rust&style=flat)](https://crates.io/crates/nexflex)
[![License](https://img.shields.io/badge/license-MIT%2FApache--2.0-blue.svg?style=flat)](#license)
[![Telegram](https://img.shields.io/badge/Telegram-Channel-2CA5E0?style=flat&logo=telegram&logoColor=white)](https://t.me/getfromme)
[![Support](https://img.shields.io/badge/Support-Crypto-F7931A?style=flat&logo=bitcoin&logoColor=white)](#optional-support)
</div>

[nexflex-walkthrough.webm](https://github.com/user-attachments/assets/7554a7e5-6ff5-49ec-9d87-f821ea99950e)

## Features

- **Streaming:** Movies, TV series, anime, Asian dramas, and community Stremio addons across multiple native providers.
- **Live TV:** M3U playlist import with channel categories, EPG support, and search.
- **Resolution Picker:** Direct stream quality selection (`4K`, `1080p`, `720p`, `480p`, `Auto`) before playback.
- **Hardware Players:** Direct launch in `mpv`, `VLC`, or `IINA` with custom auth header and cookie forwarding.
- **Batch Downloader:** Multi-segment concurrent downloader with HTTP range pause and resume for episodes and full seasons.
- **Subtitle Picker:** Multi-language subtitle tracks extracted and selectable via an interactive picker before playback or download.
- **Terminal UI:** Vim navigation, mouse interaction, slash command palette (`/help`, `/settings`), and 9 built-in themes.
- **Cover Art:** Native Kitty, Sixel, and iTerm2 poster rendering with automatic text fallback.
- **Resume & Library:** Home deck with continue-watching timestamps, watch history, and favorites stored strictly on local disk. Zero telemetry.

## Prerequisites

- **Media Player:** `mpv`, `VLC`, or `IINA` (macOS) / any external video player (Android).
- **Posters:** Terminal with Sixel, Kitty, or iTerm2 support (Ghostty, Kitty, WezTerm, iTerm2, foot, Windows Terminal v1.22+).
- **DASH Downloads:** `yt-dlp` and `ffmpeg` (required only for MovieBox DASH downloads).

## Installation

> **What works right now:** the direct installers (`install.sh`, `install.ps1`) and
> `cargo install --git …` — they download the published release.
> **Homebrew, Scoop, winget and npm need a one-time publish each** (a tap repo, a bucket,
> a manifest PR, and `npm publish`); see *Publishing* below. Until then those commands 404.

### macOS & Linux

If you have [Homebrew](https://brew.sh/) on macOS:
```bash
brew tap Mohammedsayeed-builder/nexflex-tui https://github.com/Mohammedsayeed-builder/NEXFLEX-tui
brew install nexflex-tui
```

Direct install via Terminal (macOS & Linux, no package manager needed):
```bash
curl -fsSL https://raw.githubusercontent.com/Mohammedsayeed-builder/NEXFLEX-tui/main/install.sh | bash && exec "$SHELL" -l
```

`exec "$SHELL" -l` reloads your shell afterwards so `nexflex` is on PATH straight away. On
Termux the binary is installed to `$PREFIX/bin`, which is already on PATH, so the reload is
harmless but not required.

The installer shows an animated banner and a film-strip progress bar, verifies the
SHA256 checksum before writing anything, offers to install mpv with your consent, and
ends on a "NOW SHOWING" screen. It falls back to plain output when piped, in CI, when
`NO_COLOR` is set or with `--no-animation`. Other flags: `--version <tag>`,
`--dir <path>`, `--force`, `--dry-run`, `--no-modify-path`, `--yes`, `--uninstall`.

### npm (all platforms with a prebuilt binary)

```bash
npm install -g nexflex-tui
exec "$SHELL" -l     # reload PATH, then: nexflex
```

The npm package is a small launcher that pulls the matching prebuilt binary
(`nexflex-tui-linux-x64`, `-linux-arm64`, `-darwin-x64`, `-darwin-arm64`, `-win32-x64`).

**Not on npm yet.** The tarballs are built and ready, but nothing is published to the registry,
so `npm install -g nexflex-tui` currently returns 404. Publish once with:

```bash
# after downloading the vX.Y.Z release assets into ./artifacts
node npm/scripts/prepare-platforms.mjs ./artifacts X.Y.Z
for d in npm/platforms/*/; do (cd "$d" && npm publish --access public); done
(cd npm && npm publish --access public)
```

Or set `NPM_TOKEN` as a repository secret and publish a GitHub release — the
`npm publish` workflow does the same thing with `--provenance`.

### Windows

If you have [Scoop](https://scoop.sh/) (recommended):
```powershell
scoop bucket add nexflex-tui https://github.com/Mohammedsayeed-builder/NEXFLEX-tui
scoop install nexflex-tui
```

Direct install via PowerShell (no package manager needed):
```powershell
irm https://raw.githubusercontent.com/Mohammedsayeed-builder/NEXFLEX-tui/main/install.ps1 | iex
```

> **SmartScreen prompt:** If Windows displays *"Windows protected your PC"*, click **More info** → **Run anyway**.

The installer adds its directory to your user PATH and refreshes `$env:Path` in the current
session, so `nexflex` works as soon as it finishes — no new window needed.

### Android (Termux)

On Termux the binary is installed straight into `$PREFIX/bin`, which is already on `PATH`,
so `nexflex` runs immediately after the installer finishes.

```bash
pkg update && pkg install -y curl tar termux-tools termux-am
curl -fsSL https://raw.githubusercontent.com/Mohammedsayeed-builder/NEXFLEX-tui/main/install.sh | bash
termux-setup-storage
```

<details>
<summary><b>Cargo & Source Build</b></summary>

```bash
cargo install nexflex --locked
```

From source:
```bash
git clone https://github.com/Mohammedsayeed-builder/NEXFLEX-tui.git
cd NEXFLEX
cargo build --release --locked
```

</details>

<details>
<summary><b>Verify Release Integrity</b></summary>

```bash
sha256sum -c SHA256SUMS --ignore-missing
gh attestation verify <archive-file> -R Mohammedsayeed-builder/NEXFLEX-tui
```

</details>

<details>
<summary><b>Uninstall</b></summary>

Re-run install command (`curl ... | bash` or `irm ... | iex`) and select `2) Uninstall`.

Or via package manager:
```bash
brew uninstall nexflex     # Homebrew
scoop uninstall nexflex    # Scoop
cargo uninstall nexflex    # Cargo
```

</details>

## Quick Start

```bash
nexflex
```

- Type to search, press `Enter` to play.
- Press `?` for shortcuts, or type `/settings` for preferences.

## Documentation

Full documentation at [**docs/**](docs/) or [`docs/`](docs/):

| Guide | Description |
| :--- | :--- |
| [Keyboard & Controls](docs/controls.md) | Keybindings, vim navigation, and shortcuts |
| [Configuration](docs/config.md) | Settings, themes, and environment variables |
| [Content Providers](docs/providers.md) | Native scrapers (MovieBox, 4KHDHub, Dramachi, BDIX) |
| [Stremio Addons](docs/addons-mode.md) | Community addon configuration and streaming |
| [Hardware Players](docs/players.md) | Player detection, launch options, and flags |
| [Live TV & IPTV](docs/tv-mode.md) | M3U playlist import and channel streaming |
| [Batch Downloads](docs/downloads.md) | HTTP range engine, pause, and resume |

## Contributing

Review [CONTRIBUTING.md](CONTRIBUTING.md) before submitting pull requests. Report bugs via [GitHub Issues](https://github.com/Mohammedsayeed-builder/NEXFLEX-tui/issues).

<details>
<summary><b>Support</b></summary>
<div id="optional-support" tabindex="-1"></div>

| Asset | Address |
| :--- | :--- |
| **USDT (TRC20)** | `TL4yW73qmbKZpBWwbEFgjBpwVkPDFTkJgV` |
| **Bitcoin (BTC)** | `3MEAtqtRWrQBhnaMi3Zuf5nt2efNUS2LUQ` |
| **Ethereum (EVM)** | `0x7ea20d5fa29d87f33195f5a3b211ff94038d794c` |
| **Solana (SOL)** | `6ctm5WFv73MNywoCKAz3xK72yizSspHa72rFNygooU6` |

</details>

## Privacy

Zero telemetry, analytics, or user tracking. History, favorites, and config remain local.

## License

Dual-licensed under [MIT](LICENSE-MIT) or [Apache-2.0](LICENSE-APACHE).

## Disclaimer

NEXFLEX does not host or store media. It plays publicly available streams. Users must comply with local laws.
