#!/usr/bin/env bash
# Capture and validate the live Hyprland hyprlang behavior baseline.
#
# Read-only: runs hyprctl inspection commands only. Never dispatches,
# reloads, locks, or mutates compositor state.
#
# Usage:
#   capture-hyprland-baseline.sh capture <out-dir>
#   capture-hyprland-baseline.sh validate <dir>
#   capture-hyprland-baseline.sh test
set -euo pipefail

readonly OPTIONS=(
  cursor:enable_hyprcursor
  misc:vrr
  misc:animate_manual_resizes
  misc:animate_mouse_windowdragging
  general:layout
  general:border_size
  general:resize_on_border
  general:gaps_in
  general:gaps_out
  general:col.active_border
  general:col.inactive_border
  layout:single_window_aspect_ratio
  dwindle:preserve_split
  dwindle:force_split
  decoration:rounding
  decoration:blur:enabled
  master:allow_small_split
  master:mfact
  master:new_on_top
  binds:drag_threshold
  binds:allow_workspace_cycles
  xwayland:force_zero_scaling
  ecosystem:no_update_news
)

readonly CONF_FILES=(hyprland.conf hypridle.conf hyprlock.conf hyprpaper.conf)
readonly COMPANION_PATTERN='ultrashell|hypridle|hyprpaper|hyprlock|quickshell|fuzzel|ghostty'
readonly UNIT_PATTERN='hypr|uwsm'
readonly STORE_PATH_RE='/nix/store/[a-z0-9]+/'

die() {
  echo "error: $*" >&2
  exit 1
}

require() {
  command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"
}

capture() {
  local out=$1
  require hyprctl
  require jq
  require systemctl
  [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] || die "not inside a Hyprland session"
  [[ -r "$HOME/.config/hypr/hyprland.conf" ]] || die "generated hyprland.conf is not readable"

  mkdir -p "$out/hyprctl" "$out/generated" "$out/observed"

  hyprctl version -j >"$out/hyprctl/version.json"
  hyprctl monitors -j | jq 'map(del(.id, .serial, .description))' >"$out/hyprctl/monitors.json"
  hyprctl binds -j >"$out/hyprctl/binds.json"
  hyprctl workspacerules -j >"$out/hyprctl/workspacerules.json"
  hyprctl configerrors -j >"$out/hyprctl/configerrors.json"

  local opt
  for opt in "${OPTIONS[@]}"; do
    hyprctl getoption "$opt" -j
  done | jq -s '.' >"$out/hyprctl/options.json"

  local conf
  for conf in "${CONF_FILES[@]}"; do
    [[ -r "$HOME/.config/hypr/$conf" ]] || die "generated $conf is not readable"
    sed -E "s#${STORE_PATH_RE}#/nix/store/<hash>/#g" "$HOME/.config/hypr/$conf" \
      >"$out/generated/$conf"
  done

  ps -eo comm= | sort | uniq -c | grep -E "$COMPANION_PATTERN" \
    >"$out/observed/companion-processes.txt" || true
  systemctl --user list-units --plain --no-legend 2>/dev/null |
    awk '{print $1, $3, $4}' | grep -Ei "$UNIT_PATTERN" \
    >"$out/observed/systemd-user-units.txt" || true

  jq -n \
    --arg capturedAt "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg hyprlandVersion "$(jq -r .version "$out/hyprctl/version.json")" \
    --arg capturedBy "scripts/capture-hyprland-baseline.sh" \
    '{capturedAt: $capturedAt, hyprlandVersion: $hyprlandVersion,
      capturedBy: $capturedBy,
      sanitization: [
        "monitors.json drops id, serial, and description keys",
        "conf copies replace nix store path hashes with <hash>",
        "process observations record comm names and counts only, never argv"
      ]}' >"$out/metadata.json"

  if grep -rqF "${HYPRLAND_INSTANCE_SIGNATURE}=" "$out"; then
    die "instance signature leaked into capture; remove $out"
  fi
  if grep -rqE "$STORE_PATH_RE" "$out"; then
    die "unredacted nix store path in capture; remove $out"
  fi
  echo "captured Hyprland $(jq -r .version "$out/hyprctl/version.json") baseline to $out"
}

check() {
  # check <description> <jq-filter> <file> -- passes when jq exit status is 0
  local desc=$1 filter=$2 file=$3
  if jq -e "$filter" "$file" >/dev/null 2>&1; then
    echo "ok: $desc"
  else
    echo "FAIL: $desc"
    return 1
  fi
}

check_file() {
  local desc=$1 file=$2
  if [[ -s "$file" ]]; then
    echo "ok: $desc"
  else
    echo "FAIL: $desc"
    return 1
  fi
}

check_not() {
  # check_not <description> <pattern> <file> -- passes when grep finds nothing
  local desc=$1 pattern=$2 file=$3
  if grep -qE "$pattern" "$file"; then
    echo "FAIL: $desc"
    return 1
  else
    echo "ok: $desc"
  fi
}

validate() {
  local dir=$1
  require jq
  [[ -d "$dir" ]] || die "capture directory not found: $dir"

  local fail=0
  local conf
  for conf in "${CONF_FILES[@]}"; do
    check_file "generated/$conf exists and is non-empty" "$dir/generated/$conf" || fail=1
    check_not "generated/$conf has no unredacted store path" "$STORE_PATH_RE" \
      "$dir/generated/$conf" || fail=1
  done

  check "version.json has version and tag" '.version and .tag' "$dir/hyprctl/version.json" || fail=1
  check "monitors.json is a sanitized non-empty array" \
    'type == "array" and length >= 1 and all(.[]; has("name") and (has("serial") | not) and (has("description") | not))' \
    "$dir/hyprctl/monitors.json" || fail=1
  check "binds.json entries carry dispatcher, key, modmask, description, arg" \
    'type == "array" and length > 0 and all(.[]; has("dispatcher") and has("key") and has("modmask") and has("description") and has("arg"))' \
    "$dir/hyprctl/binds.json" || fail=1
  check "workspacerules.json entries carry workspaceString" \
    'type == "array" and length > 0 and all(.[]; has("workspaceString"))' \
    "$dir/hyprctl/workspacerules.json" || fail=1
  check "configerrors.json is an array" 'type == "array"' \
    "$dir/hyprctl/configerrors.json" || fail=1
  check "options.json entries are all set" \
    'type == "array" and length > 0 and all(.[]; has("option") and .set == true)' \
    "$dir/hyprctl/options.json" || fail=1

  check_file "observed/companion-processes.txt exists" \
    "$dir/observed/companion-processes.txt" || fail=1
  check_file "observed/systemd-user-units.txt exists" \
    "$dir/observed/systemd-user-units.txt" || fail=1
  check "metadata.json has capturedAt and hyprlandVersion" \
    '.capturedAt and .hyprlandVersion' "$dir/metadata.json" || fail=1
  if grep -rqF 'HYPRLAND_INSTANCE_SIGNATURE=' "$dir"; then
    echo "FAIL: capture contains an instance-signature assignment"
    fail=1
  else
    echo "ok: capture contains no instance-signature assignment"
  fi

  if [[ $fail -ne 0 ]]; then
    echo "validation failed for $dir" >&2
    return 1
  fi
  echo "validation passed for $dir"
}

test_suite() {
  require jq
  fixture=$(mktemp -d "${TMPDIR:-/tmp}/hypr-baseline-test.XXXXXX")
  trap 'rm -rf "$fixture"' EXIT
  mkdir -p "$fixture/hyprctl" "$fixture/generated" "$fixture/observed"

  cat >"$fixture/hyprctl/version.json" <<'EOF'
{"version": "0.55.4", "tag": "v0.55.4"}
EOF
  cat >"$fixture/hyprctl/monitors.json" <<'EOF'
[{"name": "TEST-1", "width": 5120, "height": 1440}]
EOF
  cat >"$fixture/hyprctl/binds.json" <<'EOF'
[{"modmask": 64, "key": "J", "dispatcher": "layoutmsg", "arg": "togglesplit,", "description": "Toggle window split"}]
EOF
  cat >"$fixture/hyprctl/workspacerules.json" <<'EOF'
[{"workspaceString": "1", "persistent": true}]
EOF
  echo '[""]' >"$fixture/hyprctl/configerrors.json"
  cat >"$fixture/hyprctl/options.json" <<'EOF'
[{"option": "misc:vrr", "int": 2, "set": true}]
EOF
  echo 'exec-once=ultrashell' >"$fixture/generated/hyprland.conf"
  echo 'lock_cmd=hyprlock' >"$fixture/generated/hypridle.conf"
  echo 'background {' >"$fixture/generated/hyprlock.conf"
  echo 'preload=x' >"$fixture/generated/hyprpaper.conf"
  echo '1 .ultrashell-wrapped' >"$fixture/observed/companion-processes.txt"
  echo 'hypridle.service active running' >"$fixture/observed/systemd-user-units.txt"
  cat >"$fixture/metadata.json" <<'EOF'
{"capturedAt": "2026-09-12T00:00:00Z", "hyprlandVersion": "0.55.4"}
EOF

  local failures=0

  expect_pass() {
    local desc=$1
    if validate "$fixture" >/dev/null 2>&1; then
      echo "ok: test: $desc"
    else
      echo "FAIL: test: $desc"
      failures=1
    fi
  }

  expect_fail() {
    local desc=$1
    if validate "$fixture" >/dev/null 2>&1; then
      echo "FAIL: test: $desc"
      failures=1
    else
      echo "ok: test: $desc"
    fi
  }

  expect_pass "valid synthetic capture passes"

  # Tamper: serial key in monitors.json
  jq '.[0].serial = "X"' "$fixture/hyprctl/monitors.json" >"$fixture/hyprctl/monitors.json.tmp"
  mv "$fixture/hyprctl/monitors.json.tmp" "$fixture/hyprctl/monitors.json"
  expect_fail "serial key in monitors.json is rejected" "sanitized monitors"
  jq 'del(.[0].serial)' "$fixture/hyprctl/monitors.json" >"$fixture/hyprctl/monitors.json.tmp"
  mv "$fixture/hyprctl/monitors.json.tmp" "$fixture/hyprctl/monitors.json"

  # Tamper: bind entry missing description
  jq '.[0] |= del(.description)' "$fixture/hyprctl/binds.json" >"$fixture/hyprctl/binds.json.tmp"
  mv "$fixture/hyprctl/binds.json.tmp" "$fixture/hyprctl/binds.json"
  expect_fail "bind entry without description is rejected" "bind shape"
  jq '.[0].description = "Toggle window split"' "$fixture/hyprctl/binds.json" \
    >"$fixture/hyprctl/binds.json.tmp"
  mv "$fixture/hyprctl/binds.json.tmp" "$fixture/hyprctl/binds.json"

  # Tamper: unset option
  jq '.[0].set = false' "$fixture/hyprctl/options.json" >"$fixture/hyprctl/options.json.tmp"
  mv "$fixture/hyprctl/options.json.tmp" "$fixture/hyprctl/options.json"
  expect_fail "unset option is rejected" "option set flag"
  jq '.[0].set = true' "$fixture/hyprctl/options.json" >"$fixture/hyprctl/options.json.tmp"
  mv "$fixture/hyprctl/options.json.tmp" "$fixture/hyprctl/options.json"

  # Tamper: unredacted store path in a conf copy
  echo 'exec=/nix/store/abc123/pkg/bin/tool' >>"$fixture/generated/hyprland.conf"
  expect_fail "unredacted store path is rejected" "store path redaction"
  sed -i '$d' "$fixture/generated/hyprland.conf"

  # Tamper: truncated JSON
  echo '[{"modmask"' >"$fixture/hyprctl/binds.json"
  expect_fail "truncated binds.json is rejected" "JSON parse"
  cat >"$fixture/hyprctl/binds.json" <<'EOF'
[{"modmask": 64, "key": "J", "dispatcher": "layoutmsg", "arg": "togglesplit,", "description": "Toggle window split"}]
EOF

  expect_pass "restored synthetic capture passes again"

  # Validate the committed artifacts when run from the repo root
  if [[ -d docs/research/hyprland-live-baseline ]]; then
    if validate docs/research/hyprland-live-baseline >/dev/null 2>&1; then
      echo "ok: test: committed baseline validates"
    else
      echo "FAIL: test: committed baseline validates"
      failures=1
    fi
  fi

  if [[ $failures -ne 0 ]]; then
    die "self-test failed"
  fi
  echo "self-test passed"
}

case "${1:-}" in
  capture) [[ $# -eq 2 ]] || die "usage: $0 capture <out-dir>"; capture "$2" ;;
  validate) [[ $# -eq 2 ]] || die "usage: $0 validate <dir>"; validate "$2" ;;
  test) test_suite ;;
  *) die "usage: $0 {capture <out-dir>|validate <dir>|test}" ;;
esac
