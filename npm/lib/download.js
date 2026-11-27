"use strict";

// Fallback path: when the matching nexflex-tui-<platform> package was not
// installed (npm --omit=optional, a blocked postinstall, or a brand new
// platform), fetch the release archive from this project's GitHub releases and
// cache the binary. No dependencies.

const fs = require("fs");
const os = require("os");
const path = require("path");
const https = require("https");
const { execFileSync } = require("child_process");

const REPO = "Mohammedsayeed-builder/NEXFLEX-tui";

const ASSETS = {
    "linux-x64": { archive: "NEXFLEX_Linux_x64.tar.gz", exe: "nexflex" },
    "linux-arm64": { archive: "NEXFLEX_Linux_arm64.tar.gz", exe: "nexflex" },
    "darwin-x64": { archive: "NEXFLEX_macOS_Universal.tar.gz", exe: "nexflex" },
    "darwin-arm64": { archive: "NEXFLEX_macOS_Universal.tar.gz", exe: "nexflex" },
    "win32-x64": { archive: "NEXFLEX_Windows_x64.zip", exe: "nexflex.exe" },
    "android-arm64": { archive: "NEXFLEX_Android_arm64.tar.gz", exe: "nexflex" },
    "android-x64": { archive: "NEXFLEX_Android_x64.tar.gz", exe: "nexflex" },
};

function cacheRoot() {
    if (process.platform === "win32") {
        const base = process.env.LOCALAPPDATA || path.join(os.homedir(), "AppData", "Local");
        return path.join(base, "nexflex", "npm");
    }
    const base = process.env.XDG_CACHE_HOME || path.join(os.homedir(), ".cache");
    return path.join(base, "nexflex", "npm");
}

function assetFor(platformLabel) {
    return ASSETS[platformLabel] || null;
}

function baseUrl(version) {
    const override = process.env.NEXFLEX_RELEASE_URL;
    if (override) return `${override.replace(/\/+$/, "")}/`;
    return `https://github.com/${REPO}/releases/download/v${version}/`;
}

// The npm package and the release are versioned separately (the launcher is
// republished without rebuilding binaries), so ask GitHub which release is
// current and fall back to the package version.
function latestReleaseTag() {
    return new Promise((resolve) => {
        const req = https.get(
            `https://api.github.com/repos/${REPO}/releases/latest`,
            { headers: { "User-Agent": "nexflex-npm", Accept: "application/vnd.github+json" } },
            (res) => {
                if (res.statusCode !== 200) {
                    res.resume();
                    resolve(null);
                    return;
                }
                let body = "";
                res.on("data", (c) => (body += c));
                res.on("end", () => {
                    try {
                        const tag = JSON.parse(body).tag_name;
                        resolve(tag ? String(tag).replace(/^v/, "") : null);
                    } catch {
                        resolve(null);
                    }
                });
            },
        );
        req.on("error", () => resolve(null));
        req.setTimeout(10000, () => {
            req.destroy();
            resolve(null);
        });
    });
}

function fetchTo(url, dest) {
    return new Promise((resolve, reject) => {
        if (url.startsWith("file:")) {
            try {
                fs.copyFileSync(new URL(url), dest);
                resolve();
            } catch (err) {
                reject(err);
            }
            return;
        }
        const request = https.get(url, { headers: { "User-Agent": "nexflex-npm" } }, (res) => {
            if (res.statusCode === 301 || res.statusCode === 302 || res.statusCode === 307) {
                res.resume();
                fetchTo(res.headers.location, dest).then(resolve, reject);
                return;
            }
            if (res.statusCode !== 200) {
                res.resume();
                reject(new Error(`HTTP ${res.statusCode} for ${url}`));
                return;
            }
            const out = fs.createWriteStream(dest);
            res.pipe(out);
            out.on("finish", () => out.close(resolve));
            out.on("error", reject);
        });
        request.on("error", reject);
        request.setTimeout(120000, () => request.destroy(new Error("download timed out")));
    });
}

function extract(archive, dir) {
    fs.mkdirSync(dir, { recursive: true });
    if (archive.endsWith(".zip")) {
        execFileSync("tar", ["-xf", archive, "-C", dir], { stdio: "ignore" });
    } else {
        execFileSync("tar", ["-xzf", archive, "-C", dir], { stdio: "ignore" });
    }
}

// Returns the path of a usable binary, downloading it once if necessary.
async function ensureBinary(platformLabel, version, log) {
    const asset = assetFor(platformLabel);
    if (!asset) return null;

    const target = path.join(cacheRoot(), version, asset.exe);
    if (fs.existsSync(target)) return target;

    const work = fs.mkdtempSync(path.join(os.tmpdir(), "nexflex-npm-"));
    const archive = path.join(work, asset.archive);
    try {
        let releaseVersion = version;
        if (!process.env.NEXFLEX_RELEASE_URL) {
            const tag = await latestReleaseTag();
            if (tag) releaseVersion = tag;
        }
        if (log) log(`Downloading NEXFLEX ${releaseVersion} for ${platformLabel}...`);
        await fetchTo(baseUrl(releaseVersion) + asset.archive, archive);
        extract(archive, work);
        const found = path.join(work, asset.exe);
        if (!fs.existsSync(found)) throw new Error(`${asset.exe} is missing from ${asset.archive}`);
        fs.mkdirSync(path.dirname(target), { recursive: true });
        fs.copyFileSync(found, target);
        fs.chmodSync(target, 0o755);
        return target;
    } catch (err) {
        if (log) log(`Download failed: ${err.message}`);
        return null;
    } finally {
        try {
            fs.rmSync(work, { recursive: true, force: true });
        } catch {}
    }
}

module.exports = { ensureBinary, assetFor, cacheRoot, REPO };
