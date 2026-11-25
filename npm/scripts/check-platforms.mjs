#!/usr/bin/env node
// prepack guard: refuse to publish the launcher if no platform package has a binary.
import { existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const npmRoot = join(dirname(fileURLToPath(import.meta.url)), "..");
const platforms = ["linux-x64", "linux-arm64", "darwin-x64", "darwin-arm64", "win32-x64"];
const present = platforms.filter((p) =>
    existsSync(join(npmRoot, "platforms", p, "bin", p === "win32-x64" ? "nexflex.exe" : "nexflex")),
);
console.log(`check-platforms: ${present.length}/${platforms.length} platform binaries present (${present.join(", ") || "none"})`);
if (present.length === 0) {
    console.error("check-platforms: refusing to publish without any prebuilt binary");
    process.exit(1);
}
