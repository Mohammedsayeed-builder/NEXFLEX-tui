# nexflex (npm)

Install the NEXFLEX terminal app with npm:

```bash
npm install -g nexflex
npx nexflex
```

The package is a tiny launcher. The binary itself ships in a per-platform
package (`@nexflex/linux-x64`, `@nexflex/linux-arm64`, `@nexflex/darwin-x64`,
`@nexflex/darwin-arm64`, `@nexflex/win32-x64`) pulled in as an optional
dependency — the same approach esbuild uses.

Supported: linux x64/arm64, macOS x64/arm64, Windows x64.

On the first launch the installer screen is shown once (npm hides postinstall
output, so it lives there); `npm_config_foreground_scripts=true` shows it again,
`--no-animation` or `NO_COLOR=1` turns it off.

Created by Mohammed Sayeed. Based on MovieBox-TUI by mesamirh.
