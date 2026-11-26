"use strict";

// The same look as install.sh / install.ps1, in plain Node with no dependencies.

const ESC = "\u001b[";
const tty = process.stdout.isTTY === true;
const noColor = Boolean(process.env.NO_COLOR) || process.env.TERM === "dumb";
const isCI = Boolean(process.env.CI || process.env.GITHUB_ACTIONS);
const unicode = process.stdout.isTTY ? process.env.LANG !== "C" : false;

const color = !noColor && tty && !isCI;

const C = color
    ? {
          reset: `${ESC}0m`, bold: `${ESC}1m`,
          mauve: `${ESC}38;2;203;166;247m`, blue: `${ESC}38;2;137;180;250m`,
          sapphire: `${ESC}38;2;116;199;236m`, teal: `${ESC}38;2;148;226;213m`,
          green: `${ESC}38;2;166;227;161m`, yellow: `${ESC}38;2;249;226;175m`,
          red: `${ESC}38;2;243;139;168m`, text: `${ESC}38;2;205;214;244m`,
          muted: `${ESC}38;2;108;112;134m`,
      }
    : Object.fromEntries(["reset","bold","mauve","blue","sapphire","teal","green","yellow","red","text","muted"].map((k) => [k, ""]));

const ART = [
    "███╗   ██╗███████╗██╗  ██╗███████╗██╗     ███████╗██╗  ██╗",
    "████╗  ██║██╔════╝╚██╗██╔╝██╔════╝██║     ██╔════╝╚██╗██╔╝",
    "██╔██╗ ██║█████╗   ╚███╔╝ █████╗  ██║     █████╗   ╚███╔╝ ",
    "██║╚██╗██║██╔══╝   ██╔██╗ ██╔══╝  ██║     ██╔══╝   ██╔██╗ ",
    "██║ ╚████║███████╗██╔╝ ██╗██║     ███████╗███████╗██╔╝ ██╗",
    "╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝╚═╝  ╚═╝",
];

const ROW_COLORS = [C.mauve, C.blue, C.sapphire, C.teal, C.green, C.mauve];

function sleep(ms) {
    if (!tty || isCI || noColor) return;
    const until = Date.now() + ms;
    while (Date.now() < until) {
        // short spin: keeps the total animation budget tight without timers
    }
}

function glitch(line, percent) {
    const chars = "01#$%&@*+=<>/";
    let out = "";
    for (const ch of line) {
        if (ch !== " " && Math.random() * 100 < percent) {
            out += chars[Math.floor(Math.random() * chars.length)];
        } else {
            out += ch;
        }
    }
    return out;
}

function write(text) {
    process.stdout.write(text);
}

function banner(creator = "Mohammed Sayeed") {
    const animate = tty && !isCI && !noColor;
    const cols = process.stdout.columns || 80;
    const pad = Math.max(0, Math.floor((cols - 58) / 2));
    const indent = " ".repeat(pad);

    if (!animate) {
        if (!tty) {
            write(`NEXFLEX - Created by ${creator}\n`);
            return;
        }
        ART.forEach((line, i) => write(`${indent}${ROW_COLORS[i]}${line}${C.reset}\n`));
        write(`${indent}${C.sapphire}${C.bold}Created by ${creator}${C.reset}\n\n`);
        return;
    }

    write(`${ESC}?25l`);
    for (const percent of [92, 62, 32, 10]) {
        ART.forEach((line, i) => write(`${indent}${ROW_COLORS[i]}${glitch(line, percent)}${C.reset}\n`));
        write(`${ESC}${ART.length}A`);
        sleep(110);
    }
    for (let shift = 0; shift < 4; shift++) {
        ART.forEach((line, i) => {
            const col = shift === 3 ? C.mauve : ROW_COLORS[(i + shift) % ROW_COLORS.length];
            write(`${indent}${col}${line}${C.reset}\n`);
        });
        if (shift < 3) write(`${ESC}${ART.length}A`);
        sleep(70);
    }
    write(`${indent}${C.sapphire}${C.bold}Created by ${creator}${C.reset}\n\n`);
    write(`${ESC}?25h`);
}

function strip(current, state = "run") {
    const seg = [];
    for (let i = 1; i <= 5; i++) {
        if (i < current) seg.push("▓▓▓");
        else if (i === current) seg.push(state === "done" ? "▓▓▓" : state === "fail" ? "×××" : "▒▒▒");
        else seg.push("░░░");
    }
    write(`  ${C.sapphire}▐${seg.join("│")}▌${C.reset}\n`);
}

function finale({ version, path, creator = "Mohammed Sayeed" }) {
    const width = 46;
    const rule = "─".repeat(width);
    const cols = process.stdout.columns || 80;
    const pad = " ".repeat(Math.max(0, Math.floor((cols - width - 2) / 2)));
    const rows = [
        `${C.yellow}${C.bold}NOW SHOWING${C.reset}`,
        `${C.text}NEXFLEX ${version}${C.reset}`,
        `${C.text}${path.length > width - 4 ? "…" + path.slice(-(width - 5)) : path}${C.reset}`,
        "",
        `${C.green}Run: nexflex${C.reset}`,
        `${C.text}by ${creator}${C.reset}`,
    ];
    const visible = (text) => text.replace(/\u001b\[[0-9;]*m/g, "").length;
    write(`\n${pad}${C.mauve}╔${rule}╗${C.reset}\n`);
    for (const row of rows) {
        const gap = Math.max(0, width - 2 - visible(row));
        write(`${pad}${C.mauve}║${C.reset}  ${row}${" ".repeat(gap)}${C.mauve}║${C.reset}\n`);
    }
    write(`${pad}${C.mauve}╚${rule}╝${C.reset}\n\n`);
}

function missingPlatform(label, version) {
    const supported = "linux-x64, linux-arm64, darwin-x64, darwin-arm64, win32-x64";
    console.error(`${C.red}✖${C.reset} No prebuilt NEXFLEX ${version} binary for ${label}.`);
    console.error(`  Supported platforms: ${supported}`);
    console.error("");
    console.error("  Install another way:");
    console.error(`    ${C.bold}npm install -g nexflex-tui${C.reset}`);
    console.error(`    ${C.bold}curl -fsSL https://raw.githubusercontent.com/Mohammedsayeed-builder/NEXFLEX-tui/main/install.sh | bash${C.reset}`);
    console.error(`    ${C.bold}cargo install nexflex --locked${C.reset}`);
    console.error("");
}

module.exports = { banner, strip, finale, missingPlatform, C };
