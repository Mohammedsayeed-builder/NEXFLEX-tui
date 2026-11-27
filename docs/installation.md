# Installation

NEXFLEX is available across macOS, Linux, Windows, and Android (Termux).

---

## macOS and Linux

### Homebrew (macOS)

If you have [Homebrew](https://brew.sh/):

```bash
brew tap Mohammedsayeed-builder/nexflex-tui https://github.com/Mohammedsayeed-builder/NEXFLEX-tui
brew install nexflex-tui
```

> [!NOTE]
> If Homebrew prompts for tap verification on initial install, run `brew trust Mohammedsayeed-builder/nexflex-tui`.

### Direct Terminal Script

No package manager required. Open Terminal and run:

```bash
curl -fsSL https://raw.githubusercontent.com/Mohammedsayeed-builder/NEXFLEX-tui/main/install.sh | bash && exec "$SHELL" -l
```

---

## Windows

### Scoop Package Manager (Recommended)

If you have [Scoop](https://scoop.sh/):

```powershell
scoop bucket add nexflex-tui https://github.com/Mohammedsayeed-builder/NEXFLEX-tui
scoop install nexflex-tui
```

### Direct PowerShell Script

No package manager required. Open **PowerShell** and run:

```powershell
irm https://raw.githubusercontent.com/Mohammedsayeed-builder/NEXFLEX-tui/main/install.ps1 | iex
```

> **SmartScreen prompt:** If Windows displays *"Windows protected your PC"*, click **More info** → **Run anyway**.
---

## Android (Termux)

Open Termux and run:

```bash
pkg update && pkg install -y curl tar termux-tools termux-am
curl -fsSL https://raw.githubusercontent.com/Mohammedsayeed-builder/NEXFLEX-tui/main/install.sh | bash && exec "$SHELL" -l
termux-setup-storage
```

> [!IMPORTANT]
> Video playback on Android launches through your installed external media player (such as VLC, Just Player, or MX Player).
---

## Cargo (Crates.io)

Install directly using Cargo:

```bash
cargo install nexflex --locked
```

---

## Compile from Source

Clone the repository and build the release binary:

```bash
git clone https://github.com/Mohammedsayeed-builder/NEXFLEX-tui.git
cd NEXFLEX
cargo build --release --locked
```

The compiled binary will be located at `target/release/nexflex`.

---

## Verify Release Integrity

All release assets include cryptographically signed SHA-256 checksums and GitHub provenance attestations:

```bash
sha256sum -c SHA256SUMS --ignore-missing
gh attestation verify <archive-file> -R Mohammedsayeed-builder/NEXFLEX-tui
```
---

## Uninstallation

### Automated Installer (macOS, Linux, Windows, Android)

Simply re-run your original install command (`curl ... | bash` or `irm ... | iex`). When NEXFLEX is already installed, the installer automatically detects it and displays an interactive menu:

```text
NEXFLEX is already installed.
What would you like to do?
  1) Reinstall / Update to latest version
  2) Uninstall
  3) Cancel
```

Enter `2` to completely remove NEXFLEX from your system.

### Package Managers

```bash
brew uninstall nexflex     # Homebrew (macOS)
scoop uninstall nexflex    # Scoop (Windows)
cargo uninstall nexflex    # Cargo
```
