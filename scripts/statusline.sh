#!/usr/bin/env bash
# claudez status line: model · context used
input="$(cat)"
model="$(jq -r '.model.display_name // .model.id // "GLM-5.3"' <<<"$input")"
ctx="$(jq -r '.context_window.used_percentage // empty | floor' <<<"$input" 2>/dev/null)"
printf '%s' "$model"
[ -n "$ctx" ] && printf ' · ctx %s%%' "$ctx"
