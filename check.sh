#!/usr/bin/env bash
# Invariants for this repo. Run from the repo root:  ./check.sh
set -uo pipefail

fail=0
ok()   { printf '  ok    %s\n' "$1"; }
bad()  { printf '  FAIL  %s\n' "$1"; fail=1; }
section() { printf '\n%s\n' "$1"; }

cd "$(dirname "$0")"

# ---------------------------------------------------------------- secrets
# This repo is checked out as ~/.config/opencode, the same directory opencode
# writes its credential store into.
section '1. no secret is tracked'
leaked=$(git ls-files | grep -iE '(^|/)(.*-)?api-key$|\.key$|(^|/)\.env$|(^|/)auth\.json$' || true)
if [ -n "$leaked" ]; then
  bad "tracked secret-shaped files:"; printf '        %s\n' $leaked
else
  ok 'no api-key / .key / .env / auth.json tracked'
fi

if git ls-files -z | xargs -0 grep -lE '(sk-|Bearer )[A-Za-z0-9_-]{16,}' 2>/dev/null | grep -q .; then
  bad 'a tracked file contains something shaped like a bearer token'
else
  ok 'no bearer-token-shaped string in tracked files'
fi

# ---------------------------------------------------------------- layout
# The tree maps 1:1 onto ~/.config/opencode, so `git pull` IS the update.
section '2. layout maps onto ~/.config/opencode'
for f in opencode.json AGENTS.md; do
  if git ls-files --error-unmatch "$f" >/dev/null 2>&1; then ok "$f at repo root"
  else bad "$f missing from repo root"; fi
done
if git ls-files | grep -q '^config/'; then
  bad 'files still tracked under config/ — that layout cannot be a working tree'
else
  ok 'no leftover config/ directory'
fi

# ---------------------------------------------------------------- json
section '3. every tracked json parses'
for f in $(git ls-files '*.json'); do
  if jq -e . "$f" >/dev/null 2>&1; then ok "$f"; else bad "$f is not valid json"; fi
done

# ---------------------------------------------------------------- shared config
# This config is shared across the company. A private endpoint or a model only
# one machine can reach makes it unusable for everyone else — which is exactly
# what was stripped out of the personal config this was derived from.
section '4. nothing machine-specific is pinned'
if [ ! -f opencode.json ]; then
  bad 'opencode.json absent'
else
  # Every string in the config except the OAuth callback, which is loopback by design.
  priv=$(jq -r 'delpaths([paths(scalars) as $p | select($p[-1] == "redirectUri") | $p])
                | [paths(scalars) as $p | "\($p | join(".")) = \(getpath($p))"] | .[]' opencode.json \
         | grep -E '://(127\.0\.0\.1|localhost|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.|100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.)' || true)
  if [ -n "$priv" ]; then
    bad 'private or loopback endpoint in a shared config:'; printf '        %s\n' "$priv"
  else
    ok 'no private or loopback endpoint pinned'
  fi

  if [ "$(jq -r 'has("provider")' opencode.json)" = true ]; then
    bad 'opencode.json declares a custom provider — that belongs in a per-machine override, not here'
  else
    ok 'no custom provider declared'
  fi
fi

# ---------------------------------------------------------------- plugins
# "plugin" entries are npm specs opencode fetches and EXECUTES. The opencode-*
# naming is only a proxy; a plugin published under another name proves itself
# with the opencode-plugin keyword, read from the local opencode cache when
# present and from npm otherwise.
section '5. every declared plugin is plausibly an opencode plugin'
plugins=$([ -f opencode.json ] && jq -r '.plugin // [] | .[]' opencode.json)
if [ ! -f opencode.json ]; then
  bad 'opencode.json absent'
elif [ -z "$plugins" ]; then
  ok 'no plugins declared'
else
  kw='(.keywords // []) | index("opencode-plugin")'
  for p in $plugins; do
    cached="$HOME/.cache/opencode/packages/$p/node_modules/$p/package.json"
    if printf '%s' "$p" | grep -qE '^(@[a-z0-9._-]+/)?opencode-[a-z0-9._-]+$|-opencode-plugin$'; then
      ok "$p (named opencode-*)"
    elif jq -e "$kw" "$cached" >/dev/null 2>&1 ||
         npm view "$p" --json 2>/dev/null | jq -e "$kw" >/dev/null 2>&1; then
      ok "$p (declares the opencode-plugin keyword)"
    else
      bad "$p is neither named opencode-* / *-opencode-plugin nor declares the opencode-plugin keyword — verify it is really a plugin"
    fi
  done
fi

# ---------------------------------------------------------------- skills
section '6. every skill is tracked and has valid frontmatter'
skills=$(git ls-files 'skills/*/SKILL.md')
if [ -z "$skills" ]; then
  bad 'no skills tracked — no plugin installs them, so they must be versioned here'
else
  for s in $skills; do
    if head -1 "$s" | grep -q '^---$' && grep -qE '^name: ' "$s" && grep -qE '^description: ' "$s"; then
      ok "$s has name+description frontmatter"
    else
      bad "$s is missing valid skill frontmatter"
    fi
  done
fi

# ---------------------------------------------------------------- subagents
# opencode ships `explore` and `general` as native subagents compiled into the
# binary. The personal config this was derived from disabled both, because one
# GPU with a single KV slot cannot serve two prompt prefixes. That constraint is
# not the company's — nobody inherits the restriction by accident.
section '7. no agent is disabled'
if [ ! -f opencode.json ]; then
  bad 'opencode.json absent'
else
  off=$(jq -r '.agent // {} | to_entries[] | select(.value.disable == true) | .key' opencode.json)
  if [ -n "$off" ]; then
    bad 'agents disabled in a shared config:'; printf '        %s\n' $off
  else
    ok 'explore, general and every other agent stay dispatchable'
  fi
fi

# ---------------------------------------------------------------- mcp
section '8. both mcp servers are configured and enabled'
if [ ! -f opencode.json ]; then
  bad 'opencode.json absent'
else
  for s in cavemem yggdrasil; do
    if [ "$(jq -r --arg s "$s" '.mcp[$s].enabled // false' opencode.json)" = true ]; then
      ok "mcp $s is enabled"
    else
      bad "mcp $s is missing or disabled — it is the point of this config"
    fi
  done
fi

# ---------------------------------------------------------------- mcp oauth
# opencode's McpOAuthConfig is camelCase with additionalProperties:false. A
# snake_case key is not a typo that fails loudly — it is dropped, and the client
# silently runs on defaults.
section '9. every mcp oauth key is one opencode understands'
if [ ! -f opencode.json ]; then
  bad 'opencode.json absent'
else
  stray=$(jq -r '.mcp // {} | to_entries[] | .key as $s | (.value.oauth // {}) | keys[]
                 | select(. as $k | ["callbackPort","clientId","clientSecret","redirectUri","scope"] | index($k) | not)
                 | "\($s).oauth.\(.)"' opencode.json)
  if [ -n "$stray" ]; then
    bad 'mcp oauth keys outside McpOAuthConfig — opencode drops these:'
    printf '        %s\n' $stray
  else
    ok 'no unknown mcp oauth key'
  fi
fi

section ''
if [ "$fail" -eq 0 ]; then echo 'all checks passed'; else echo 'FAILED'; fi
exit "$fail"
