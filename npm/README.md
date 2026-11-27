# nexflex (npm)

Install the NEXFLEX terminal app with npm:

```bash
npm install -g nexflex-tui
exec "$SHELL" -l     # reload PATH, then: nexflex
```

The package is a tiny launcher. The binary itself ships in a per-platform
package (`nexflex-tui-linux-x64`, `nexflex-tui-linux-arm64`, `nexflex-tui-darwin-x64`,
`nexflex-tui-darwin-arm64`, `nexflex-tui-win32-x64`) pulled in as an optional
dependency — the same approach esbuild uses.

Supported: linux x64/arm64, macOS x64/arm64, Windows x64, Android/Termux arm64.

On the first launch the installer screen is shown once (npm hides postinstall
output, so it lives there); `npm_config_foreground_scripts=true` shows it again,
`--no-animation` or `NO_COLOR=1` turns it off.

Created by Mohammed Sayeed.

## Publishing (maintainer)

```bash
# 1. download the release assets for the version you are publishing
mkdir -p artifacts && cd artifacts
for a in NEXFLEX_Linux_x64.tar.gz NEXFLEX_Linux_arm64.tar.gz \
         NEXFLEX_macOS_Universal.tar.gz NEXFLEX_Windows_x64.zip \
         NEXFLEX_Android_arm64.tar.gz; do
  curl -fsSLO "https://github.com/Mohammedsayeed-builder/NEXFLEX-tui/releases/download/v0.1.30/$a"
done
cd ..

# 2. drop the binaries into the platform packages and bump every version
node npm/scripts/prepare-platforms.mjs ./artifacts 0.1.30

# 3. publish the platform packages first, then the launcher
for d in npm/platforms/*/; do (cd "$d" && npm publish --access public); done
(cd npm && npm publish --access public)
```

`npm login` first, and the account must own the `nexflex-tui` name. In CI the same steps run in
`.github/workflows/npm-publish.yml` when `NPM_TOKEN` is set.
