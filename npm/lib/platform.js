"use strict";

const path = require("path");

const SUPPORTED = {
    "linux-x64": "nexflex",
    "linux-arm64": "nexflex",
    "darwin-x64": "nexflex",
    "darwin-arm64": "nexflex",
    "win32-x64": "nexflex.exe",
    // Termux / Android
    "android-arm64": "nexflex",
    "android-x64": "nexflex",
};

function packageName() {
    return `nexflex-tui-${process.platform}-${process.arch}`;
}

function platformLabel() {
    return `${process.platform}-${process.arch}`;
}

function isSupported() {
    return Object.prototype.hasOwnProperty.call(SUPPORTED, platformLabel());
}

// Returns the absolute path of the prebuilt binary, or null when the matching
// optional dependency was not installed (unsupported platform, --omit=optional,
// or a failed download).
function resolveBinary() {
    if (!isSupported()) return null;
    const name = packageName();
    const exe = SUPPORTED[platformLabel()];
    let dir;
    try {
        dir = path.dirname(require.resolve(`${name}/package.json`));
    } catch {
        return null;
    }
    const candidate = path.join(dir, "bin", exe);
    return require("fs").existsSync(candidate) ? candidate : null;
}

module.exports = { resolveBinary, platformLabel, isSupported, packageName, SUPPORTED };
