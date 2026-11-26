#!/usr/bin/env node
"use strict";

// Thin launcher: hand over to the prebuilt binary shipped in the matching
// @nexflex/<platform>-<arch> package (the esbuild pattern). If that optional
// dependency is missing, fall back to downloading the release archive once.
const { spawn } = require("child_process");
const path = require("path");
const fs = require("fs");
const os = require("os");

const { resolveBinary, platformLabel } = require("../lib/platform");
const { ensureBinary } = require("../lib/download");
const ui = require("../lib/installer-ui");
const pkg = require("../package.json");

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

function showWelcome(binary) {
    // npm hides postinstall output, so the installer screen lives here: on the
    // first launch, and whenever npm runs scripts in the foreground.
    const foreground = process.env.npm_config_foreground_scripts === "true";
    if (quiet) return;
    if (!firstRun() && !foreground) return;
    ui.banner();
    ui.strip(5, "done");
    ui.finale({ version: pkg.version, path: binary, creator: "Mohammed Sayeed" });
}

function run(binary) {
    const child = spawn(binary, args, { stdio: "inherit" });
    child.on("error", (err) => {
        console.error(`nexflex: could not start ${binary}: ${err.message}`);
        process.exit(1);
    });
    child.on("exit", (code, signal) => {
        if (signal) process.kill(process.pid, signal);
        process.exit(code === null ? 1 : code);
    });
}

(async () => {
    let binary = resolveBinary();

    if (!binary) {
        binary = await ensureBinary(platformLabel(), pkg.version, quiet ? null : (m) => console.error(`  ${m}`));
    }

    if (!binary) {
        if (!quiet) ui.banner();
        ui.missingPlatform(platformLabel(), pkg.version);
        process.exit(1);
    }

    showWelcome(binary);
    run(binary);
})();
