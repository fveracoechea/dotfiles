#!/usr/bin/env bash
set -euo pipefail

input=$(cat)

model=$(jq -r '.model.display_name' <<<"$input")
effort=$(jq -r '.effort.level // empty' <<<"$input")
used_pct=$(jq -r '.context_window.used_percentage // empty' <<<"$input")
five_hour_pct=$(jq -r '.rate_limits.five_hour.used_percentage // empty' <<<"$input")
seven_day_pct=$(jq -r '.rate_limits.seven_day.used_percentage // empty' <<<"$input")

if [ -n "$effort" ]; then
  model_part="$model ($effort)"
else
  model_part="$model"
fi

parts=("$model_part")

if [ -n "$used_pct" ]; then
  parts+=("$(printf 'ctx: %.0f%%' "$used_pct")")
fi

if [ -n "$five_hour_pct" ]; then
  parts+=("$(printf '5h: %.0f%%' "$five_hour_pct")")
fi

if [ -n "$seven_day_pct" ]; then
  parts+=("$(printf '7d: %.0f%%' "$seven_day_pct")")
fi

status=""
for p in "${parts[@]}"; do
  if [ -z "$status" ]; then
    status="$p"
  else
    status="$status | $p"
  fi
done

printf '%s' "$status"
