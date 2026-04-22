#!/usr/bin/env bash
# Claude Code status line script
# Receives JSON via stdin; outputs a single status line string.

input=$(cat)

# --- Extract fields ---
model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
dir=$(basename "$cwd")
session_name=$(echo "$input" | jq -r '.session_name // empty')

used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')

five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')
agent_name=$(echo "$input" | jq -r '.agent.name // empty')
worktree_branch=$(echo "$input" | jq -r '.worktree.branch // empty')

effort=$(echo "$input" | jq -r '.effort_level // empty')
if [ -z "$effort" ]; then
  effort=$(jq -r '.effortLevel // empty' ~/.claude/settings.json 2>/dev/null)
fi

# --- ANSI colors (dimmed-friendly) ---
RESET=$'\033[0m'
DIM=$'\033[2m'
BOLD=$'\033[1m'
CYAN=$'\033[36m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
BLUE=$'\033[34m'
MAGENTA=$'\033[35m'
WHITE=$'\033[37m'

# --- Helper: format time until reset ---
time_until_reset() {
  local epoch="$1"
  if [ -z "$epoch" ]; then echo ""; return; fi
  local now=$(date +%s)
  local secs=$(( epoch - now ))
  if [ "$secs" -le 0 ]; then echo "now"; return; fi
  local days=$(( secs / 86400 ))
  local hrs=$(( (secs % 86400) / 3600 ))
  local mins=$(( (secs % 3600) / 60 ))
  if [ "$days" -gt 0 ]; then
    printf "%dd%dh" "$days" "$hrs"
  elif [ "$hrs" -gt 0 ]; then
    printf "%dh%02dm" "$hrs" "$mins"
  else
    printf "%dm" "$mins"
  fi
}

# --- Helper: context bar (10 chars) ---
context_bar() {
  local pct="$1"
  local filled=$(echo "$pct" | awk '{printf "%d", $1 / 10}')
  local filled_bar="" empty_bar=""
  for i in $(seq 1 10); do
    if [ "$i" -le "$filled" ]; then
      filled_bar="${filled_bar}█"
    else
      empty_bar="${empty_bar}░"
    fi
  done
  # Colour: green < 60%, yellow < 80%, red >= 80%
  local colour="$GREEN"
  if [ "$(echo "$pct >= 80" | bc -l 2>/dev/null)" = "1" ]; then
    colour="$RED"
  elif [ "$(echo "$pct >= 60" | bc -l 2>/dev/null)" = "1" ]; then
    colour="$YELLOW"
  fi
  printf "${colour}${filled_bar}${DIM}${empty_bar}${RESET}"
}

# --- Build output ---
parts=()

# Directory
parts+=("$(printf "${CYAN}${BOLD}%s${RESET}" "$dir")")

# Session name (if set)
if [ -n "$session_name" ]; then
  parts+=("$(printf "${MAGENTA}[%s]${RESET}" "$session_name")")
fi

# Git worktree branch
if [ -n "$worktree_branch" ]; then
  parts+=("$(printf "${BLUE}(wt:%s)${RESET}" "$worktree_branch")")
fi

# Agent name
if [ -n "$agent_name" ]; then
  parts+=("$(printf "${YELLOW}agent:%s${RESET}" "$agent_name")")
fi

# Vim mode
if [ -n "$vim_mode" ]; then
  if [ "$vim_mode" = "INSERT" ]; then
    parts+=("$(printf "${GREEN}[INSERT]${RESET}")")
  else
    parts+=("$(printf "${YELLOW}[NORMAL]${RESET}")")
  fi
fi

# Model
parts+=("$(printf "${WHITE}%s${RESET}" "$model")")

# Effort level
if [ -n "$effort" ]; then
  case "$effort" in
    low)    effort_colour="$GREEN"  ;;
    medium) effort_colour="$YELLOW" ;;
    high)   effort_colour="$RED"    ;;
    max)    effort_colour="$MAGENTA" ;;
    *)      effort_colour="$DIM"    ;;
  esac
  parts+=("$(printf "${effort_colour}effort:%s${RESET}" "$effort")")
fi

# Context usage (percentage remaining)
if [ -n "$used_pct" ]; then
  remaining=$(echo "$used_pct" | awk '{printf "%.0f", 100 - $1}')
  bar=$(context_bar "$used_pct")
  parts+=("$(printf "ctx:%s${DIM}%s%% left%s" "$bar" "$remaining" "$RESET")")
fi

# Rate limits
rate_parts=()
if [ -n "$five_pct" ]; then
  fp=$(printf "%.0f" "$five_pct")
  colour="$GREEN"
  [ "$(echo "$five_pct >= 80" | bc -l 2>/dev/null)" = "1" ] && colour="$RED"
  [ "$(echo "$five_pct >= 60" | bc -l 2>/dev/null)" = "1" ] && colour="$YELLOW"
  five_reset_str=$(time_until_reset "$five_reset")
  if [ -n "$five_reset_str" ]; then
    rate_parts+=("$(printf "${colour}5h:%s%%${RESET}${DIM}(%s)${RESET}" "$fp" "$five_reset_str")")
  else
    rate_parts+=("$(printf "${colour}5h:%s%%%s" "$fp" "$RESET")")
  fi
fi
if [ -n "$week_pct" ]; then
  wp=$(printf "%.0f" "$week_pct")
  colour="$GREEN"
  [ "$(echo "$week_pct >= 80" | bc -l 2>/dev/null)" = "1" ] && colour="$RED"
  [ "$(echo "$week_pct >= 60" | bc -l 2>/dev/null)" = "1" ] && colour="$YELLOW"
  week_reset_str=$(time_until_reset "$week_reset")
  if [ -n "$week_reset_str" ]; then
    rate_parts+=("$(printf "${colour}7d:%s%%${RESET}${DIM}(%s)${RESET}" "$wp" "$week_reset_str")")
  else
    rate_parts+=("$(printf "${colour}7d:%s%%%s" "$wp" "$RESET")")
  fi
fi
if [ "${#rate_parts[@]}" -gt 0 ]; then
  parts+=("$(printf "limits:%s" "$(IFS='/'; echo "${rate_parts[*]}")")")
fi

# --- Join with separators and print ---
sep="$(printf " ${DIM}|${RESET} ")"
result=""
for part in "${parts[@]}"; do
  if [ -z "$result" ]; then
    result="$part"
  else
    result="${result}${sep}${part}"
  fi
done

printf "%s" "$result"
