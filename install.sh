#!/usr/bin/env bash
# NEXFLEX installer — Linux (x86_64/aarch64), macOS, Termux.
#
#   curl -fsSL https://raw.githubusercontent.com/Mohammedsayeed-builder/NEXFLEX-tui/main/install.sh | bash
#   ./install.sh [OPTIONS]
#
# Created by Mohammed Sayeed.
set -euo pipefail

APP_NAME="NEXFLEX"
BIN_NAME="nexflex"
REPO="Mohammedsayeed-builder/NEXFLEX-tui"
CREATOR="Mohammed Sayeed"
DEFAULT_INSTALL_DIR="${NEXFLEX_INSTALL_DIR:-$HOME/.local/bin}"

VERSION=""
CUSTOM_DIR=""
FORCE=0
DRY_RUN=0
NO_MODIFY_PATH=0
UNINSTALL=0
NO_ANIMATION=0
ASSUME_YES=0

while [ $# -gt 0 ]; do
    case "$1" in
        --version=*|-v=*) VERSION="${1#*=}"; shift ;;
        --version|-v)
            if [ $# -lt 2 ] || [ -z "${2:-}" ]; then
                printf "error: --version requires a release tag argument.\n" >&2
                exit 1
            fi
            VERSION="${2:-}"; shift 2 ;;
        --dir=*) CUSTOM_DIR="${1#*=}"; shift ;;
        --dir)
            if [ $# -lt 2 ] || [ -z "${2:-}" ]; then
                printf "error: --dir requires a path argument.\n" >&2
                exit 1
            fi
            CUSTOM_DIR="${2:-}"; shift 2 ;;
        --force|-f) FORCE=1; shift ;;
        --dry-run) DRY_RUN=1; shift ;;
        --no-modify-path) NO_MODIFY_PATH=1; shift ;;
        --uninstall) UNINSTALL=1; shift ;;
        --no-animation|--no-anim|--plain) NO_ANIMATION=1; shift ;;
        --yes|-y) ASSUME_YES=1; shift ;;
        --no-color) export NO_COLOR=1; shift ;;
        --help|-h)
            cat << EOF
$APP_NAME Installer

USAGE:
    curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash -s -- [OPTIONS]
    ./install.sh [OPTIONS]

OPTIONS:
    -v, --version <tag>    Install a specific version (e.g. v0.1.30)
        --dir <path>       Install the binary to a custom directory
    -f, --force            Reinstall even if already at the latest version
        --dry-run          Perform preflight checks without writing files
        --no-modify-path   Do not modify shell profile configuration
        --uninstall        Uninstall $APP_NAME from your system
        --no-animation     Plain output, no banner or progress animation
    -y, --yes              Assume yes for prompts (e.g. installing mpv)
        --no-color         Disable colour
    -h, --help             Show this help message

Created by $CREATOR.
EOF
            exit 0 ;;
        *) printf "warning: ignoring unknown argument: %s\n" "$1" >&2; shift ;;
    esac
done

while [ -n "$CUSTOM_DIR" ] && [ "${CUSTOM_DIR%/}" != "$CUSTOM_DIR" ]; do
    CUSTOM_DIR="${CUSTOM_DIR%/}"
done

# ---------------------------------------------------------------------------
# Output capabilities: truecolor -> 256-colour -> plain; Unicode -> ASCII.
# ---------------------------------------------------------------------------
IS_TTY=0
[ -t 1 ] && IS_TTY=1

IS_CI=0
[ -n "${CI:-}" ] || [ -n "${GITHUB_ACTIONS:-}" ] || [ -n "${BUILD_NUMBER:-}" ] && IS_CI=1

UNICODE=1
case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
    *UTF-8*|*utf8*|*UTF8*|*utf-8*) UNICODE=1 ;;
    "") UNICODE=1 ;;
    *) UNICODE=0 ;;
esac
[ "${TERM:-}" = "linux" ] && UNICODE=0

COLOR_MODE="plain"
if [ -z "${NO_COLOR:-}" ] && [ "${TERM:-}" != "dumb" ] && [ "$IS_TTY" -eq 1 ]; then
    case "${COLORTERM:-}" in
        truecolor|24bit) COLOR_MODE="truecolor" ;;
        *)
            case "${TERM_PROGRAM:-}" in
                iTerm.app|Apple_Terminal|WezTerm|ghostty|vscode|WarpTerminal) COLOR_MODE="truecolor" ;;
                *) case "${TERM:-}" in
                       *direct*) COLOR_MODE="truecolor" ;;
                       *256color*) COLOR_MODE="256" ;;
                       *) COLOR_MODE="plain" ;;
                   esac ;;
            esac ;;
    esac
fi

ANIM=1
if [ "$IS_TTY" -ne 1 ] || [ "$NO_ANIMATION" -eq 1 ] || [ "$IS_CI" -eq 1 ] \
   || [ "${TERM:-}" = "dumb" ] || [ -n "${NO_COLOR:-}" ] || [ "$COLOR_MODE" = "plain" ]; then
    ANIM=0
fi

C_RESET=""
C_BOLD=""
C_DIM=""
C_MAUVE=""
C_BLUE=""
C_SAPPHIRE=""
C_LAVENDER=""
C_TEAL=""
C_GREEN=""
C_YELLOW=""
C_RED=""
C_TEXT=""
C_SUBTEXT=""
C_MUTED=""
CURSOR_HIDE=""
CURSOR_SHOW=""

setup_colors() {
    [ "$COLOR_MODE" = "plain" ] && return 0
    C_RESET=$'\033[0m'
    C_BOLD=$'\033[1m'
    C_DIM=$'\033[2m'
    CURSOR_HIDE=$'\033[?25l'
    CURSOR_SHOW=$'\033[?25h'
    if [ "$COLOR_MODE" = "truecolor" ]; then
        C_MAUVE=$'\033[38;2;203;166;247m'
        C_BLUE=$'\033[38;2;137;180;250m'
        C_SAPPHIRE=$'\033[38;2;116;199;236m'
        C_LAVENDER=$'\033[38;2;180;190;254m'
        C_TEAL=$'\033[38;2;148;226;213m'
        C_GREEN=$'\033[38;2;166;227;161m'
        C_YELLOW=$'\033[38;2;249;226;175m'
        C_RED=$'\033[38;2;243;139;168m'
        C_TEXT=$'\033[38;2;205;214;244m'
        C_SUBTEXT=$'\033[38;2;166;173;200m'
        C_MUTED=$'\033[38;2;108;112;134m'
    else
        C_MAUVE=$'\033[38;5;183m'
        C_BLUE=$'\033[38;5;111m'
        C_SAPPHIRE=$'\033[38;5;117m'
        C_LAVENDER=$'\033[38;5;147m'
        C_TEAL=$'\033[38;5;116m'
        C_GREEN=$'\033[38;5;151m'
        C_YELLOW=$'\033[38;5;223m'
        C_RED=$'\033[38;5;211m'
        C_TEXT=$'\033[38;5;252m'
        C_SUBTEXT=$'\033[38;5;145m'
        C_MUTED=$'\033[38;5;242m'
    fi
}
setup_colors

# Gradient palette used by the banner sweep, one colour per art row.
ROW_COLORS=("$C_MAUVE" "$C_BLUE" "$C_SAPPHIRE" "$C_TEAL" "$C_GREEN" "$C_LAVENDER")

# ---------------------------------------------------------------------------
# Cleanup / signal handling: the cursor always comes back.
# ---------------------------------------------------------------------------
cleanup() {
    printf "%b" "$CURSOR_SHOW" 2>/dev/null || true
    if [ -n "${TMP_VER_FILE:-}" ] && [ -f "${TMP_VER_FILE:-}" ]; then rm -f "$TMP_VER_FILE"; fi
    if [ -n "${TMP_DIR:-}" ] && [ -d "${TMP_DIR:-}" ]; then rm -rf "$TMP_DIR"; fi
    if [ -n "${DL_PID:-}" ] && kill -0 "$DL_PID" 2>/dev/null; then kill "$DL_PID" 2>/dev/null || true; fi
}
trap cleanup EXIT
trap 'printf "\n"; exit 130' INT
trap 'exit 143' TERM

# ---------------------------------------------------------------------------
# Wordmark art
# ---------------------------------------------------------------------------
ART_UNICODE=(
    "███╗   ██╗███████╗██╗  ██╗███████╗██╗     ███████╗██╗  ██╗"
    "████╗  ██║██╔════╝╚██╗██╔╝██╔════╝██║     ██╔════╝╚██╗██╔╝"
    "██╔██╗ ██║█████╗   ╚███╔╝ █████╗  ██║     █████╗   ╚███╔╝ "
    "██║╚██╗██║██╔══╝   ██╔██╗ ██╔══╝  ██║     ██╔══╝   ██╔██╗ "
    "██║ ╚████║███████╗██╔╝ ██╗██║     ███████╗███████╗██╔╝ ██╗"
    "╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝╚═╝  ╚═╝"
)
ART_ASCII=(
    ' _   _ _______  _______ _     _______  __'
    '| \ | | ____\ \/ /  ___| |   | ____\ \/ /'
    '|  \| |  _|  \  /| |_  | |   |  _|  \  /'
    '| |\  | |___ /  \|  _| | |___| |___ /  \'
    '|_| \_|_____/_/\_\_|   |_____|_____/_/\_\'
)
ART_ASCII_SMALL=(
    ' _  _ _____  _____ _    _____  __'
    '| \| | __\ \/ / __| |  | __\ \/ /'
    '| .` | _| >  <| _|| |__| _| >  <'
    '|_|\_|___/_/\_\_| |____|___/_/\_\'
)

ART=()
ART_WIDTH=0

pick_art() {
    local cols
    cols=$(get_terminal_cols)
    if [ "$UNICODE" -eq 1 ]; then
        ART=("${ART_UNICODE[@]}")
        ART_WIDTH=58
    elif [ "$cols" -ge 42 ]; then
        ART=("${ART_ASCII[@]}")
        ART_WIDTH=42
    else
        ART=("${ART_ASCII_SMALL[@]}")
        ART_WIDTH=33
    fi
}

get_terminal_cols() {
    local cols=""
    if [ -n "${COLUMNS:-}" ] && [[ "$COLUMNS" =~ ^[0-9]+$ ]] && [ "$COLUMNS" -gt 0 ]; then
        cols="$COLUMNS"
    elif [ -t 1 ] || [ -t 2 ]; then
        cols=$(tput cols 2>/dev/null || true)
        if [ -z "$cols" ] || [ "$cols" -le 0 ] 2>/dev/null; then
            cols=$(stty size 2>/dev/null | awk '{print $2}')
        fi
    fi
    if [ -z "$cols" ] || [ "$cols" -le 0 ] 2>/dev/null; then cols=80; fi
    printf "%s" "$cols"
}

# Replace a fraction of the visible characters with noise characters.
# Fills the global GLITCHED array with one glitched copy of the wordmark.
GLITCHED=()
glitch_block() {
    local percent="$1"
    local chars='01#$%&@*+=<>/'
    local n=${#chars}
    local line out ch i
    GLITCHED=()
    for line in "${ART[@]}"; do
        out=""
        for (( i = 0; i < ${#line}; i++ )); do
            ch="${line:i:1}"
            if [ "$ch" != " " ] && [ $(( RANDOM % 100 )) -lt "$percent" ]; then
                out+="${chars:$(( RANDOM % n )):1}"
            else
                out+="$ch"
            fi
        done
        GLITCHED+=("$out")
    done
}

print_art_row() {
    local line="$1" color="$2" pad="$3"
    if [ "${#line}" -lt "$ART_WIDTH" ]; then
        printf -v line "%-${ART_WIDTH}s" "$line"
    fi
    if [ -n "$color" ]; then
        printf "%*s%b%s%b\n" "$pad" "" "$color" "$line" "$C_RESET"
    else
        printf "%*s%s\n" "$pad" "" "$line"
    fi
}

print_static_banner() {
    if [ "$IS_TTY" -ne 1 ]; then
        printf "%s installer — Created by %s\n" "$APP_NAME" "$CREATOR"
        return 0
    fi
    pick_art
    local cols pad
    cols=$(get_terminal_cols)
    pad=0
    if [ "$cols" -gt "$ART_WIDTH" ]; then pad=$(( (cols - ART_WIDTH) / 2 )); fi
    local sub="Created by $CREATOR"
    local sub_pad=0
    if [ "$cols" -gt "${#sub}" ]; then sub_pad=$(( (cols - ${#sub}) / 2 )); fi
    for line in "${ART[@]}"; do print_art_row "$line" "" "$pad"; done
    printf "%*s%s\n\n" "$sub_pad" "" "$sub"
}

anim_banner() {
    if [ "$ANIM" -eq 0 ]; then
        print_static_banner
        return 0
    fi

    pick_art
    local cols pad rows i frame threshold
    cols=$(get_terminal_cols)
    pad=0
    if [ "$cols" -gt "$ART_WIDTH" ]; then pad=$(( (cols - ART_WIDTH) / 2 )); fi
    rows=${#ART[@]}
    printf "%b" "$CURSOR_HIDE"

    # Phase 1 — decode/glitch to clean (≈0.45s)
    local threshold
    for threshold in 92 62 32 10; do
        glitch_block "$threshold"
        for i in "${!ART[@]}"; do
            print_art_row "${GLITCHED[$i]}" "${ROW_COLORS[$i]}" "$pad"
        done
        if [ "$threshold" -ne 10 ]; then
            printf "\033[%dA" "$rows"
            sleep 0.11
        fi
    done

    # Phase 2 — gradient sweep across the resolved wordmark (≈0.4s)
    local shift j color
    for shift in 0 1 2 3; do
        for i in "${!ART[@]}"; do
            j=$(( (i + shift) % ${#ROW_COLORS[@]} ))
            color="${ROW_COLORS[$j]}"
            if [ "$shift" -eq 3 ]; then color="$C_MAUVE"; fi
            print_art_row "${ART[$i]}" "$color" "$pad"
        done
        if [ "$shift" -lt 3 ]; then
            printf "\033[%dA" "$rows"
            sleep 0.07
        fi
    done

    # Subtitle
    local sub="Created by $CREATOR"
    local sub_pad=0
    if [ "$cols" -gt "${#sub}" ]; then sub_pad=$(( (cols - ${#sub}) / 2 )); fi
    printf "%*s%b%b%s%b\n\n" "$sub_pad" "" "$C_SAPPHIRE" "$C_BOLD" "$sub" "$C_RESET"
    printf "%b" "$CURSOR_SHOW"
}

# ---------------------------------------------------------------------------
# Film-strip progress bar
# ---------------------------------------------------------------------------
STEP_TOTAL=5
STEP_CURRENT=0

draw_strip() {
    local state="${1:-run}"
    local filled="" i mark
    for i in $(seq 1 "$STEP_TOTAL"); do
        if [ "$i" -lt "$STEP_CURRENT" ]; then mark="done"
        elif [ "$i" -eq "$STEP_CURRENT" ]; then mark="$state"
        else mark="todo"; fi
        case "$mark" in
            done) if [ "$UNICODE" -eq 1 ]; then filled="$filled▓▓▓"; else filled="$filled###"; fi ;;
            run)  if [ "$UNICODE" -eq 1 ]; then filled="$filled▒▒▒"; else filled="$filled~~~"; fi ;;
            fail) if [ "$UNICODE" -eq 1 ]; then filled="$filled×××"; else filled="$filled!!!"; fi ;;
            *)    if [ "$UNICODE" -eq 1 ]; then filled="$filled░░░"; else filled="$filled   "; fi ;;
        esac
        if [ "$i" -lt "$STEP_TOTAL" ]; then
            if [ "$UNICODE" -eq 1 ]; then filled="$filled│"; else filled="$filled|"; fi
        fi
    done
    if [ "$UNICODE" -eq 1 ]; then
        printf "  %b▐%s▌%b\n" "$C_SAPPHIRE" "$filled" "$C_RESET"
    else
        printf "  [%s]\n" "$filled"
    fi
}

SPIN_UNICODE=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
SPIN_ASCII=("-" "\\" "|" "/")

spinner_frame() {
    local idx="$1"
    if [ "$UNICODE" -eq 1 ]; then
        printf "%s" "${SPIN_UNICODE[$(( idx % ${#SPIN_UNICODE[@]} ))]}"
    else
        printf "%s" "${SPIN_ASCII[$(( idx % ${#SPIN_ASCII[@]} ))]}"
    fi
}

OK_MARK="✔"
FAIL_MARK="✖"
INFO_MARK="ℹ"
WARN_MARK="⚠"
if [ "$UNICODE" -eq 0 ]; then OK_MARK="OK"; FAIL_MARK="!!"; INFO_MARK="i"; WARN_MARK="!"; fi

step_begin() {
    STEP_CURRENT=$1
    STEP_LABEL="$2"
    if [ "$ANIM" -eq 1 ]; then
        draw_strip "run"
        printf "\r\033[K  %b%s%b %b%s%b" "$C_SAPPHIRE" "$(spinner_frame 0)" "$C_RESET" "$C_TEXT" "$STEP_LABEL" "$C_RESET"
    else
        printf "  %b[%d/%d]%b %s..." "$C_BLUE" "$STEP_CURRENT" "$STEP_TOTAL" "$C_RESET" "$STEP_LABEL"
    fi
}

step_ok() {
    if [ "$ANIM" -eq 1 ]; then
        printf "\r\033[K"
        draw_strip "done"
    else
        printf " done\n"
    fi
    printf "  %b%s%b %b%s%b\n" "$C_GREEN" "$OK_MARK" "$C_RESET" "$C_TEXT" "$1" "$C_RESET"
}

step_fail() {
    local message="$1" reason="${2:-}"
    if [ "$ANIM" -eq 1 ]; then
        printf "\r\033[K"
        draw_strip "fail"
    else
        printf " failed\n"
    fi
    printf "  %b%s%b %b%s%b\n" "$C_RED" "$FAIL_MARK" "$C_RESET" "$C_TEXT" "$message" "$C_RESET" >&2
    if [ -n "$reason" ]; then
        printf "    %b%s%b\n" "$C_MUTED" "$reason" "$C_RESET" >&2
    fi
}

# Run a command as the current step, animating a spinner while it works.
run_step() {
    local label="$1"
    shift
    local tmp_out
    tmp_out=$(mktemp)

    if [ "$ANIM" -ne 1 ]; then
        step_begin "$STEP_CURRENT" "$label"
        if "$@" > "$tmp_out" 2>&1; then
            rm -f "$tmp_out"
            return 0
        fi
        local reason
        reason=$(tail -n 3 "$tmp_out" 2>/dev/null | tr '\n' ' ')
        rm -f "$tmp_out"
        step_fail "$label failed" "${reason:-no output}"
        return 1
    fi

    step_begin "$STEP_CURRENT" "$label"
    "$@" > "$tmp_out" 2>&1 &
    local pid=$!
    local idx=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r\033[K  %b%s%b %b%s%b" "$C_SAPPHIRE" "$(spinner_frame "$idx")" "$C_RESET" "$C_TEXT" "$label" "$C_RESET"
        idx=$(( idx + 1 ))
        sleep 0.06
    done
    local exit_code=0
    wait "$pid" || exit_code=$?
    printf "\r\033[K"

    if [ "$exit_code" -ne 0 ]; then
        local reason
        reason=$(tail -n 3 "$tmp_out" 2>/dev/null | tr '\n' ' ')
        rm -f "$tmp_out"
        step_fail "$label failed" "${reason:-no output}"
        return "$exit_code"
    fi
    rm -f "$tmp_out"
    return 0
}

# ---------------------------------------------------------------------------
# Platform detection
# ---------------------------------------------------------------------------
OS="$(uname -s)"
ARCH="$(uname -m)"
IS_TERMUX=0
[ -n "${TERMUX_VERSION:-}" ] && IS_TERMUX=1
[ -n "${PREFIX:-}" ] && case "$PREFIX" in *com.termux*) IS_TERMUX=1 ;; esac

FILE=""
case "$OS" in
    Linux)
        if [ "$IS_TERMUX" -eq 1 ]; then
            case "$ARCH" in
                aarch64|arm64) FILE="NEXFLEX_Android_arm64.tar.gz" ;;
            esac
        else
            case "$ARCH" in
                x86_64|amd64) FILE="NEXFLEX_Linux_x64.tar.gz" ;;
                aarch64|arm64) FILE="NEXFLEX_Linux_arm64.tar.gz" ;;
            esac
        fi ;;
    Darwin)
        FILE="NEXFLEX_macOS_Universal.tar.gz" ;;
esac

detect_platform() {
    if [ -z "$FILE" ]; then
        return 1
    fi
    return 0
}

platform_reason() {
    case "$OS" in
        Linux)
            if [ "$IS_TERMUX" -eq 1 ]; then
                echo "unsupported Termux architecture ($ARCH); only arm64/aarch64 is hosted"
            else
                echo "unsupported architecture ($ARCH); supported: x86_64, aarch64"
            fi ;;
        Darwin) echo "unsupported macOS architecture ($ARCH)" ;;
        *) echo "unsupported operating system ($OS); Windows users should run install.ps1" ;;
    esac
}

# ---------------------------------------------------------------------------
# Uninstall
# ---------------------------------------------------------------------------
do_uninstall() {
    anim_banner
    STEP_CURRENT=1
    step_begin 1 "Locating $BIN_NAME"
    local targets=() p
    for p in "${PREFIX:-/nonexistent}/bin/$BIN_NAME" "$DEFAULT_INSTALL_DIR/$BIN_NAME" \
             "$HOME/.local/bin/$BIN_NAME" "/usr/local/bin/$BIN_NAME" "/opt/homebrew/bin/$BIN_NAME"; do
        [ -f "$p" ] && targets+=("$p")
    done
    local on_path
    on_path=$(command -v "$BIN_NAME" 2>/dev/null || true)
    if [ -n "$on_path" ] && [ -f "$on_path" ]; then
        local seen=0 t
        for t in "${targets[@]:-}"; do [ "$t" = "$on_path" ] && seen=1; done
        [ "$seen" -eq 0 ] && targets+=("$on_path")
    fi
    if [ "${#targets[@]}" -eq 0 ]; then
        step_fail "No $BIN_NAME installation found" "checked $DEFAULT_INSTALL_DIR, /usr/local/bin"
        return 0
    fi
    step_ok "Found $BIN_NAME at ${targets[0]}"

    STEP_CURRENT=2
    run_step "Removing binary" remove_binaries "${targets[@]}" || return 1
    step_ok "Removed ${#targets[@]} binary file(s)"

    STEP_CURRENT=3
    local cfg="$HOME/.config/$BIN_NAME" data="$HOME/.local/share/$BIN_NAME" cache="$HOME/.cache/$BIN_NAME"
    step_begin 3 "Removing configuration"
    if [ -d "$cfg" ] || [ -d "$data" ] || [ -d "$cache" ]; then
        rm -rf "$cfg" "$data" "$cache" 2>/dev/null || true
        step_ok "Removed config, data and cache"
    else
        step_ok "No configuration to remove"
    fi

    STEP_CURRENT=4
    step_begin 4 "Cleaning shell profile"
    local rc
    for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.config/fish/config.fish"; do
        [ -f "$rc" ] || continue
        if grep -Fq "$DEFAULT_INSTALL_DIR" "$rc" 2>/dev/null; then
            cp "$rc" "$rc.nexflex.bak"
            grep -Fv "$DEFAULT_INSTALL_DIR" "$rc.nexflex.bak" > "$rc" || cp "$rc.nexflex.bak" "$rc"
            rm -f "$rc.nexflex.bak"
        fi
    done
    step_ok "PATH entries removed (backup kept during edit)"

    STEP_CURRENT=5
    step_begin 5 "Finalising"
    step_ok "$APP_NAME uninstalled"
    printf "\n  %b%s was removed.%b Restart your terminal to refresh PATH.\n\n" "$C_TEXT" "$APP_NAME" "$C_RESET"
}

remove_binaries() {
    local t
    for t in "$@"; do rm -f "$t"; done
}

# ---------------------------------------------------------------------------
# Version resolution
# ---------------------------------------------------------------------------
TMP_VER_FILE=""
resolve_version() {
    if [ -n "$VERSION" ]; then
        printf "%s" "$VERSION" > "$TMP_VER_FILE"
        return 0
    fi
    local api="https://api.github.com/repos/$REPO/releases/latest"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --max-time 20 "$api" 2>/dev/null \
            | awk -F'"' '/"tag_name"/ {print $4; exit}' > "$TMP_VER_FILE" || true
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- --timeout=20 "$api" 2>/dev/null \
            | awk -F'"' '/"tag_name"/ {print $4; exit}' > "$TMP_VER_FILE" || true
    fi
    [ -s "$TMP_VER_FILE" ] || return 1
    return 0
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
if [ "$UNINSTALL" -eq 1 ]; then
    do_uninstall
    exit 0
fi

# Where the binary goes. Termux keeps user binaries in $PREFIX/bin, which is
# already on PATH in every session, so nothing has to be exported there.
if [ -n "$CUSTOM_DIR" ]; then
    INSTALL_DIR="$CUSTOM_DIR"
elif [ "$IS_TERMUX" -eq 1 ] && [ -n "${PREFIX:-}" ] && [ -d "${PREFIX}/bin" ]; then
    INSTALL_DIR="$PREFIX/bin"
elif [ -w "$DEFAULT_INSTALL_DIR" ] || [ ! -e "$DEFAULT_INSTALL_DIR" ]; then
    INSTALL_DIR="$DEFAULT_INSTALL_DIR"
elif [ -w /usr/local/bin ]; then
    INSTALL_DIR="/usr/local/bin"
else
    INSTALL_DIR="$DEFAULT_INSTALL_DIR"
fi
APP_PATH="$INSTALL_DIR/$BIN_NAME"

WAS_ON_PATH=0
case ":$PATH:" in *":$INSTALL_DIR:"*) WAS_ON_PATH=1 ;; esac

TMP_VER_FILE=$(mktemp)
TMP_DIR=""

STEP_CURRENT=1
run_step "Detecting platform ($OS/$ARCH)" detect_platform || {
    step_fail "Unsupported platform" "$(platform_reason)"
    printf "\n  %b%s%b Install from source instead: %bcargo install nexflex --locked%b\n\n" \
        "$C_SAPPHIRE" "$INFO_MARK" "$C_RESET" "$C_BOLD" "$C_RESET" >&2
    exit 1
}
step_ok "Platform detected: $OS/$ARCH → $FILE"

printf "  %b·%b Resolving release version...\n" "$C_MUTED" "$C_RESET"
if ! resolve_version; then
    step_fail "Could not resolve the latest release" "pass --version <tag> to install a specific release"
    exit 1
fi
TARGET_VERSION=$(cat "$TMP_VER_FILE" 2>/dev/null || true)
if [ -z "$TARGET_VERSION" ]; then
    step_fail "Could not resolve the latest release" "pass --version <tag> to install a specific release"
    exit 1
fi
printf "  %b%s%b %bLatest release: %s%b\n" "$C_GREEN" "$OK_MARK" "$C_RESET" "$C_TEXT" "$TARGET_VERSION" "$C_RESET"

if [ -n "${NEXFLEX_RELEASE_URL:-}" ]; then
    URL="${NEXFLEX_RELEASE_URL%/}/$FILE"
    CHECKSUM_URL="${NEXFLEX_RELEASE_URL%/}/SHA256SUMS"
else
    URL="https://github.com/$REPO/releases/download/$TARGET_VERSION/$FILE"
    CHECKSUM_URL="https://github.com/$REPO/releases/download/$TARGET_VERSION/SHA256SUMS"
fi

EXISTING_BIN=$(command -v "$BIN_NAME" 2>/dev/null || true)
if [ -n "$EXISTING_BIN" ] && [ "$FORCE" -eq 0 ] && [ "$DRY_RUN" -eq 0 ]; then
    existing_version=$("$EXISTING_BIN" --version 2>/dev/null | awk '{print $2}' || true)
    if [ "v$existing_version" = "$TARGET_VERSION" ] || [ "$existing_version" = "$TARGET_VERSION" ]; then
        anim_banner
        printf "  %b%s%b %b%s %s is already installed at %s%b\n" "$C_YELLOW" "$INFO_MARK" "$C_RESET" \
            "$C_TEXT" "$APP_NAME" "$TARGET_VERSION" "$EXISTING_BIN" "$C_RESET"
        printf "  Use %b--force%b to reinstall.\n\n" "$C_BOLD" "$C_RESET"
        exit 0
    fi
fi

if [ "$DRY_RUN" -eq 1 ]; then
    anim_banner
    printf "  %bDry run%b — nothing was written.\n\n" "$C_BOLD" "$C_RESET"
    printf "  Package:      %s\n" "$FILE"
    printf "  Version:      %s\n" "$TARGET_VERSION"
    printf "  Source:       %s\n" "$URL"
    printf "  Checksums:    %s\n" "$CHECKSUM_URL"
    printf "  Install path: %s\n\n" "$APP_PATH"
    exit 0
fi

TMP_DIR=$(mktemp -d)

# --- download in the background, banner animation runs while it happens ---
start_download() {
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --retry 2 --max-time 300 "$URL" -o "$TMP_DIR/$FILE" \
            && curl -fsSL --max-time 60 "$CHECKSUM_URL" -o "$TMP_DIR/SHA256SUMS"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$TMP_DIR/$FILE" --timeout=300 "$URL" \
            && wget -qO "$TMP_DIR/SHA256SUMS" --timeout=60 "$CHECKSUM_URL"
    else
        printf "neither curl nor wget is available\n" >&2
        return 1
    fi
}
start_download > "$TMP_DIR/download.log" 2>&1 &
DL_PID=$!

STEP_CURRENT=2
printf "\n"
anim_banner
step_begin 2 "Downloading $FILE"

# Wait for the download, animating the spinner only while it is still running.
spin_idx=0
while kill -0 "$DL_PID" 2>/dev/null; do
    if [ "$ANIM" -eq 1 ]; then
        printf "\r\033[K  %b%s%b %b%s%b" "$C_SAPPHIRE" "$(spinner_frame "$spin_idx")" "$C_RESET" \
            "$C_TEXT" "Downloading $FILE" "$C_RESET"
    fi
    spin_idx=$(( spin_idx + 1 ))
    sleep 0.06
done
dl_status=0
wait "$DL_PID" || dl_status=$?
DL_PID=""
if [ "$ANIM" -eq 1 ]; then printf "\r\033[K"; fi
if [ "$dl_status" -ne 0 ]; then
    step_fail "Download failed" "$(tail -n 3 "$TMP_DIR/download.log" 2>/dev/null | tr '\n' ' ')"
    if [ "$IS_TERMUX" -eq 1 ]; then
        printf "\n  %b%s%b Precompiled Android binaries are published from v0.1.17 onwards.\n" "$C_SAPPHIRE" "$INFO_MARK" "$C_RESET" >&2
    fi
    printf "  Install from source instead: %bcargo install nexflex --locked%b\n\n" "$C_BOLD" "$C_RESET" >&2
    exit 1
fi
step_ok "Downloaded $FILE"

# --- verify ---
STEP_CURRENT=3
verify_checksum() {
    local expected_sha actual_sha=""
    expected_sha=$(awk -v file="$FILE" '{gsub(/^\*/, "", $2); if ($2 == file) print $1}' "$TMP_DIR/SHA256SUMS" 2>/dev/null || true)
    [ -n "$expected_sha" ] || return 1
    if command -v sha256sum >/dev/null 2>&1; then
        actual_sha=$(sha256sum "$TMP_DIR/$FILE" | awk '{print $1}')
    elif command -v shasum >/dev/null 2>&1; then
        actual_sha=$(shasum -a 256 "$TMP_DIR/$FILE" | awk '{print $1}')
    elif command -v openssl >/dev/null 2>&1; then
        actual_sha=$(openssl dgst -sha256 "$TMP_DIR/$FILE" | awk '{print $NF}')
    else
        printf "no sha256 tool available (sha256sum, shasum or openssl)\n" >&2
        return 1
    fi
    if [ "$actual_sha" != "$expected_sha" ]; then
        printf "checksum mismatch: expected %s, got %s\n" "$expected_sha" "$actual_sha" >&2
        return 1
    fi
    return 0
}
run_step "Verifying SHA256 checksum" verify_checksum || {
    printf "  %bThe download was rejected and nothing was installed.%b\n\n" "$C_TEXT" "$C_RESET" >&2
    exit 1
}
step_ok "Checksum verified against SHA256SUMS"

# --- install ---
STEP_CURRENT=4
mkdir -p "$INSTALL_DIR" 2>/dev/null || true
if [ ! -w "$INSTALL_DIR" ]; then
    if [ "$INSTALL_DIR" != "$HOME/.local/bin" ] && [ -w "$HOME" ]; then
        INSTALL_DIR="$HOME/.local/bin"
        APP_PATH="$INSTALL_DIR/$BIN_NAME"
        WAS_ON_PATH=0
        case ":$PATH:" in *":$INSTALL_DIR:"*) WAS_ON_PATH=1 ;; esac
        mkdir -p "$INSTALL_DIR" 2>/dev/null || true
    fi
fi

install_binary() {
    tar -xzf "$TMP_DIR/$FILE" -C "$TMP_DIR"
    [ -f "$TMP_DIR/$BIN_NAME" ] || { printf "archive did not contain %s\n" "$BIN_NAME" >&2; return 1; }
    rm -f "$APP_PATH"
    cp "$TMP_DIR/$BIN_NAME" "$APP_PATH"
    chmod 755 "$APP_PATH"
    "$APP_PATH" --version >/dev/null 2>&1
}
run_step "Installing to $INSTALL_DIR" install_binary || {
    step_fail "Installation failed" "the binary did not run after copying to $APP_PATH"
    exit 1
}
step_ok "Installed $APP_PATH"

# --- shell PATH ---
# The installer runs in a subshell (usually `curl | bash`), so it can never
# change the caller's PATH directly. Instead it puts the binary somewhere the
# shell will find on its own: a symlink in a directory that is already on PATH,
# or an idempotent line in every rc file the user actually has.
PATH_READY=$WAS_ON_PATH
SHELL_MODIFIED=""
SYMLINKED=""

path_contains() {
    case ":$PATH:" in *":$1:"*) return 0 ;; *) return 1 ;; esac
}

if [ "$NO_MODIFY_PATH" -eq 0 ] && [ "$PATH_READY" -eq 0 ]; then
    # 1. symlink into a writable directory that is already on PATH
    for dir in /usr/local/bin /opt/homebrew/bin "$HOME/.local/bin" "$HOME/bin"; do
        [ "$dir" = "$INSTALL_DIR" ] && continue
        path_contains "$dir" || continue
        [ -d "$dir" ] && [ -w "$dir" ] || continue
        if ln -sf "$APP_PATH" "$dir/$BIN_NAME" 2>/dev/null; then
            SYMLINKED="$dir/$BIN_NAME"
            PATH_READY=1
            break
        fi
    done
fi

if [ "$NO_MODIFY_PATH" -eq 0 ] && [ "$PATH_READY" -eq 0 ]; then
    # 2. append to every rc file that exists; create ~/.bashrc if there is none
    CURRENT_SHELL=$(basename "${SHELL:-bash}")
    RC_FILES=()
    for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile" "$HOME/.bash_profile"; do
        [ -f "$rc" ] && RC_FILES+=("$rc")
    done
    if [ "${#RC_FILES[@]}" -eq 0 ]; then
        : > "$HOME/.bashrc" 2>/dev/null && RC_FILES+=("$HOME/.bashrc")
    fi
    for rc in "${RC_FILES[@]}"; do
        [ -w "$rc" ] || continue
        if grep -Fq -- "$INSTALL_DIR" "$rc" 2>/dev/null; then
            continue
        fi
        if [ "$CURRENT_SHELL" = "fish" ]; then
            printf '\nfish_add_path %s\n' "$INSTALL_DIR" >> "$rc"
        else
            printf '\nexport PATH="%s:$PATH"\n' "$INSTALL_DIR" >> "$rc"
        fi
        SHELL_MODIFIED="${SHELL_MODIFIED:+$SHELL_MODIFIED }$rc"
    done

    # fish keeps its own config
    if [ "$CURRENT_SHELL" = "fish" ] && [ -d "$HOME/.config/fish" ]; then
        FISH_RC="$HOME/.config/fish/config.fish"
        if ! grep -Fq -- "$INSTALL_DIR" "$FISH_RC" 2>/dev/null; then
            printf '\nfish_add_path %s\n' "$INSTALL_DIR" >> "$FISH_RC"
            SHELL_MODIFIED="${SHELL_MODIFIED:+$SHELL_MODIFIED }$FISH_RC"
        fi
    fi
fi

# Make the rest of this script (and its own verification) see the binary.
export PATH="$INSTALL_DIR:$PATH"
hash -r 2>/dev/null || true

# --- player check ---
STEP_CURRENT=5
PLAYER_DETECTED=""
detect_player() {
    if [ "$OS" = "Darwin" ]; then
        if command -v iina >/dev/null 2>&1 || command -v iina-cli >/dev/null 2>&1 \
           || [ -d "/Applications/IINA.app" ] || [ -d "$HOME/Applications/IINA.app" ]; then
            PLAYER_DETECTED="IINA"
        elif command -v mpv >/dev/null 2>&1 || [ -d "/Applications/mpv.app" ]; then
            PLAYER_DETECTED="mpv"
        elif command -v vlc >/dev/null 2>&1 || [ -d "/Applications/VLC.app" ]; then
            PLAYER_DETECTED="VLC"
        fi
    else
        if command -v mpv >/dev/null 2>&1 || [ -f "$HOME/.local/share/flatpak/exports/bin/io.mpv.Mpv" ]; then
            PLAYER_DETECTED="mpv"
        elif command -v vlc >/dev/null 2>&1 || [ -f "$HOME/.local/share/flatpak/exports/bin/org.videolan.VLC" ]; then
            PLAYER_DETECTED="VLC"
        elif command -v termux-open >/dev/null 2>&1; then
            PLAYER_DETECTED="Android Player (termux intent)"
        fi
    fi
    return 0
}
run_step "Checking for a media player" detect_player || true
if [ -n "$PLAYER_DETECTED" ]; then
    step_ok "Player ready: $PLAYER_DETECTED"
else
    step_ok "No player found yet (mpv recommended)"
fi

# --- optional mpv install, only with consent ---
mpv_install_command() {
    if [ "$OS" = "Darwin" ]; then
        command -v brew >/dev/null 2>&1 && { printf "brew install mpv"; return 0; }
        return 1
    fi
    if command -v apt-get >/dev/null 2>&1; then printf "sudo apt-get install -y mpv"; return 0; fi
    if command -v dnf >/dev/null 2>&1; then printf "sudo dnf install -y mpv"; return 0; fi
    if command -v pacman >/dev/null 2>&1; then printf "sudo pacman -S --noconfirm mpv"; return 0; fi
    if command -v zypper >/dev/null 2>&1; then printf "sudo zypper install -y mpv"; return 0; fi
    if command -v apk >/dev/null 2>&1; then printf "sudo apk add mpv"; return 0; fi
    return 1
}

if [ -z "$PLAYER_DETECTED" ] && [ "$IS_TTY" -eq 1 ] && [ "$IS_TERMUX" -eq 0 ]; then
    MPV_CMD=""
    MPV_CMD=$(mpv_install_command || true)
    if [ -n "$MPV_CMD" ]; then
        answer="n"
        if [ "$ASSUME_YES" -eq 1 ]; then
            answer="y"
        elif [ -r /dev/tty ]; then
            printf "  %b%s%b mpv was not found. Install it now with %b%s%b? [y/N] " \
                "$C_SAPPHIRE" "$INFO_MARK" "$C_RESET" "$C_BOLD" "$MPV_CMD" "$C_RESET" > /dev/tty
            read -r answer < /dev/tty || answer="n"
        fi
        case "$answer" in
            y|Y|yes|YES)
                STEP_CURRENT=5
                if [ "$ANIM" -eq 1 ]; then printf "\n"; fi
                run_step "Installing mpv" bash -c "$MPV_CMD" || {
                    printf "  %bmpv was not installed; install it later with:%b %s\n" "$C_YELLOW" "$C_RESET" "$MPV_CMD" >&2
                    printf "\n"
                }
                if command -v mpv >/dev/null 2>&1; then
                    PLAYER_DETECTED="mpv"
                    step_ok "mpv installed"
                fi ;;
            *) printf "\n" ;;
        esac
    fi
fi

# ---------------------------------------------------------------------------
# NOW SHOWING
# ---------------------------------------------------------------------------
finale() {
    local line1="NOW SHOWING"
    local cols pad
    cols=$(get_terminal_cols)
    local inner=44
    pad=0
    if [ "$cols" -gt $((inner + 2)) ]; then pad=$(( (cols - inner - 2) / 2 )); fi

    printf "\n"
    if [ "$UNICODE" -eq 1 ]; then
        printf "%*s%b╔══════════════════════════════════════════════╗%b\n" "$pad" "" "$C_MAUVE" "$C_RESET"
        printf "%*s%b║%b  %b%b%-42s%b  %b║%b\n" "$pad" "" "$C_MAUVE" "$C_RESET" "$C_BOLD" "$C_YELLOW" "$line1" "$C_RESET" "$C_MAUVE" "$C_RESET"
        printf "%*s%b╟──────────────────────────────────────────────╢%b\n" "$pad" "" "$C_MAUVE" "$C_RESET"
        printf "%*s%b║%b  %-42s  %b║%b\n" "$pad" "" "$C_MAUVE" "$C_RESET" "$APP_NAME $TARGET_VERSION" "$C_MAUVE" "$C_RESET"
        printf "%*s%b║%b  %-42s  %b║%b\n" "$pad" "" "$C_MAUVE" "$C_RESET" "$APP_PATH" "$C_MAUVE" "$C_RESET"
        if [ -n "$PLAYER_DETECTED" ]; then
            printf "%*s%b║%b  %-42s  %b║%b\n" "$pad" "" "$C_MAUVE" "$C_RESET" "Player: $PLAYER_DETECTED" "$C_MAUVE" "$C_RESET"
        fi
        printf "%*s%b╟──────────────────────────────────────────────╢%b\n" "$pad" "" "$C_MAUVE" "$C_RESET"
        printf "%*s%b║%b  %bRun: nexflex%b%-30s  %b║%b\n" "$pad" "" "$C_MAUVE" "$C_RESET" "$C_GREEN" "$C_RESET" "" "$C_MAUVE" "$C_RESET"
        printf "%*s%b║%b  %-42s  %b║%b\n" "$pad" "" "$C_MAUVE" "$C_RESET" "by $CREATOR" "$C_MAUVE" "$C_RESET"
        printf "%*s%b╚══════════════════════════════════════════════╝%b\n" "$pad" "" "$C_MAUVE" "$C_RESET"
    else
        printf "%*s+----------------------------------------------+\n" "$pad" ""
        printf "%*s|  %-42s  |\n" "$pad" "" "$line1"
        printf "%*s|  %-42s  |\n" "$pad" "" "$APP_NAME $TARGET_VERSION"
        printf "%*s|  %-42s  |\n" "$pad" "" "$APP_PATH"
        [ -n "$PLAYER_DETECTED" ] && printf "%*s|  %-42s  |\n" "$pad" "" "Player: $PLAYER_DETECTED"
        printf "%*s|  %-42s  |\n" "$pad" "" "Run: nexflex"
        printf "%*s|  %-42s  |\n" "$pad" "" "by $CREATOR"
        printf "%*s+----------------------------------------------+\n" "$pad" ""
    fi
    printf "\n"
}

# --- verification: the binary must run, and the shell must be able to find it ---
STEP_CURRENT=$((STEP_TOTAL + 1))
if ! "$APP_PATH" --version >/dev/null 2>&1; then
    printf "\n  %b%s%b %bThe installed binary does not run.%b\n" "$C_RED" "$FAIL_MARK" "$C_RESET" "$C_TEXT" "$C_RESET" >&2
    printf "  Try: %bcargo install --git https://github.com/Mohammedsayeed-builder/NEXFLEX-tui nexflex --locked%b\n\n" "$C_BOLD" "$C_RESET" >&2
    exit 1
fi
if [ "$NO_MODIFY_PATH" -eq 0 ] && ! command -v "$BIN_NAME" >/dev/null 2>&1; then
    PATH_READY=0
fi

finale

if [ "$PATH_READY" -eq 0 ]; then
    if [ -n "$SHELL_MODIFIED" ]; then
        printf "  %b%s%b Run %bexec \"$SHELL\" -l%b to load the new PATH in this shell.\n\n" \
            "$C_SAPPHIRE" "$INFO_MARK" "$C_RESET" "$C_BOLD" "$C_RESET"
    else
        printf "  %b%s%b Add it to PATH for this session with:\n" \
            "$C_SAPPHIRE" "$INFO_MARK" "$C_RESET"
        printf "    %bexport PATH=\"%s:$PATH\"%b\n\n" "$C_BOLD" "$INSTALL_DIR" "$C_RESET"
    fi
fi
