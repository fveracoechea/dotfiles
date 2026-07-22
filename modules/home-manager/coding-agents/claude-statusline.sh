#!/usr/bin/env bash
set -euo pipefail

input=$(cat)

format_tokens() {
  awk -v n="$1" 'BEGIN {
    if (n >= 1000000) printf "%.1fM", n / 1000000
    else if (n >= 1000) printf "%.0fk", n / 1000
    else printf "%d", n
  }'
}

model=$(jq -r '.model.display_name' <<<"$input")
effort=$(jq -r '.effort.level // empty' <<<"$input")
used_pct=$(jq -r '.context_window.used_percentage // empty' <<<"$input")
input_tokens=$(jq -r '.context_window.total_input_tokens // empty' <<<"$input")
output_tokens=$(jq -r '.context_window.total_output_tokens // empty' <<<"$input")
context_window_size=$(jq -r '.context_window.context_window_size // empty' <<<"$input")
five_hour_pct=$(jq -r '.rate_limits.five_hour.used_percentage // empty' <<<"$input")
seven_day_pct=$(jq -r '.rate_limits.seven_day.used_percentage // empty' <<<"$input")

if [ -n "$effort" ]; then
  model_part="$model ($effort)"
else
  model_part="$model"
fi

parts=("$model_part")

if [ -n "$input_tokens" ] && [ -n "$output_tokens" ] && [ -n "$context_window_size" ]; then
  used_tokens=$((input_tokens + output_tokens))
  ctx_part="ctx: $(format_tokens "$used_tokens")/$(format_tokens "$context_window_size")"
  if [ -n "$used_pct" ]; then
    ctx_part="$ctx_part ($(printf '%.0f%%' "$used_pct"))"
  fi
  parts+=("$ctx_part")
elif [ -n "$used_pct" ]; then
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
