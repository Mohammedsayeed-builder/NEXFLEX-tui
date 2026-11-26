#!/usr/bin/env node
// Unpacks the release artifacts into the per-platform npm packages before publish.
// Usage: node npm/scripts/prepare-platforms.mjs <artifacts-dir> [version]
import { existsSync, mkdirSync, copyFileSync, readFileSync, writeFileSync, mkdtempSync, rmSync } from "node:fs";
import { join, dirname } from "node:path";
import { tmpdir } from "node:os";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";

const here = dirname(fileURLToPath(import.meta.url));
const npmRoot = join(here, "..");
const artifacts = process.argv[2] || join(npmRoot, "artifacts");
const version = process.argv[3] || JSON.parse(readFileSync(join(npmRoot, "package.json"), "utf8")).version;

const MAP = {
    "linux-x64": ["NEXFLEX_Linux_x64.tar.gz", "nexflex"],
    "linux-arm64": ["NEXFLEX_Linux_arm64.tar.gz", "nexflex"],
    "darwin-x64": ["NEXFLEX_macOS_Universal.tar.gz", "nexflex"],
    "darwin-arm64": ["NEXFLEX_macOS_Universal.tar.gz", "nexflex"],
    "win32-x64": ["NEXFLEX_Windows_x64.zip", "nexflex.exe"],
};

function unpack(archive, exe) {
    const work = mkdtempSync(join(tmpdir(), "nexflex-npm-"));
    try {
        if (archive.endsWith(".zip")) {
            execFileSync("unzip", ["-o", "-q", archive, "-d", work], { stdio: "inherit" });
        } else {
            execFileSync("tar", ["-xzf", archive, "-C", work], { stdio: "inherit" });
        }
        const found = join(work, exe);
        if (!existsSync(found)) throw new Error(`${exe} missing inside ${archive}`);
        return found;
    } finally {
        // caller copies before we clean up
        process.on("exit", () => rmSync(work, { recursive: true, force: true }));
        unpack.cleanups.push(work);
    }
}
unpack.cleanups = [];

let missing = 0;
for (const [platform, [archive, exe]] of Object.entries(MAP)) {
    const src = join(artifacts, archive);
    const dest = join(npmRoot, "platforms", platform, "bin", exe);
    if (!existsSync(src)) {
        console.warn(`prepare-platforms: ${archive} not found, nexflex-tui-${platform} will ship without a binary`);
        missing++;
        continue;
    }
    mkdirSync(dirname(dest), { recursive: true });
    copyFileSync(unpack(src, exe), dest);
    console.log(`prepare-platforms: ${archive} -> platforms/${platform}/bin/${exe}`);
}

const bump = (file) => {
    const pkg = JSON.parse(readFileSync(file, "utf8"));
    pkg.version = version;
    if (pkg.optionalDependencies) {
        for (const dep of Object.keys(pkg.optionalDependencies)) pkg.optionalDependencies[dep] = version;
    }
    writeFileSync(file, JSON.stringify(pkg, null, 2) + "\n");
};
bump(join(npmRoot, "package.json"));
for (const platform of Object.keys(MAP)) bump(join(npmRoot, "platforms", platform, "package.json"));

if (missing) console.warn(`prepare-platforms: ${missing} platform package(s) ship without a binary`);
