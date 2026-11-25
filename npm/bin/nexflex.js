#!/usr/bin/env node
"use strict";

// Thin launcher: hand over to the prebuilt binary shipped in the matching
// @nexflex/<platform>-<arch> package (the esbuild pattern). No dependencies.
const { spawn } = require("child_process");
const path = require("path");
const fs = require("fs");
const os = require("os");

const { resolveBinary, platformLabel } = require("../lib/platform");
const ui = require("../lib/installer-ui");

const args = process.argv.slice(2);
const quiet = args.includes("--no-animation") || process.env.NEXFLEX_NO_ANIMATION === "1";

function firstRun() {
    const marker = path.join(os.homedir(), ".nexflex", "npm-welcome");
    try {
        if (fs.existsSync(marker)) return false;
        fs.mkdirSync(path.dirname(marker), { recursive: true });
        fs.writeFileSync(marker, new Date().toISOString() + "\n");
        return true;
    } catch {
        return false;
    }
}

function showWelcome() {
    // npm hides postinstall output, so the installer screen lives here: on the
    // first launch, and whenever npm runs scripts in the foreground.
    const foreground = process.env.npm_config_foreground_scripts === "true";
    if (quiet) return;
    if (!firstRun() && !foreground) return;
    ui.banner();
    ui.strip(5, "done");
    ui.finale({ version: require("../package.json").version, path: resolveBinary(), creator: "Mohammed Sayeed" });
}

const binary = resolveBinary();

if (!binary) {
    if (!quiet) ui.banner();
    ui.missingPlatform(platformLabel(), process.env.npm_package_version || require("../package.json").version);
    process.exit(1);
}

showWelcome();

const child = spawn(binary, args, { stdio: "inherit" });
child.on("error", (err) => {
    console.error(`nexflex: could not start ${binary}: ${err.message}`);
    process.exit(1);
});
child.on("exit", (code, signal) => {
    if (signal) process.kill(process.pid, signal);
    process.exit(code === null ? 1 : code);
});
