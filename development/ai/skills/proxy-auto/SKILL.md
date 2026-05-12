---
name: proxy-auto
description: |
  Automatically diagnose and fix network failures by toggling the system proxy (pon/poff).
  When a bash command, git operation, package manager, curl, or any network request fails
  with connection errors, timeouts, DNS failures, or proxy errors, use this skill to check
  the current proxy state and try switching it — before asking the user what to do.
  Try toggling automatically first (if proxy is ON → turn OFF, if OFF → turn ON) and verify
  connectivity after each change. Only escalate to the user after exhausting both proxy states.
  Do NOT just report the error — use this skill to actually attempt a fix.
  Trigger on: connection refused, timeout, DNS resolution failure, proxy CONNECT errors,
  npm/git/curl network failures, "Failed to connect", "Could not resolve host",
  "Temporary failure in name resolution".
  Especially relevant for users who work behind a proxy that may be conditionally needed.
---

# proxy-auto — Automatic Proxy Switch

This skill helps diagnose and fix network failures by intelligently toggling
the `pon`/`poff` proxy functions defined in the user's shell profile.

The key idea: sometimes you need the proxy to reach external services, sometimes
the proxy itself is the problem. Instead of guessing, this skill tries both states
automatically and reports what works.

## When to trigger

When any command run by you or the user fails and the error output contains
network-related messages. Common scenarios:

- `git clone`, `git fetch`, `git pull` — "Failed to connect", "Could not read from remote"
- `npm install`, `pip install`, `go mod download` — network errors, ECONNRESET
- `curl`, `wget` — connection failures, timeouts
- `apt-get`, `brew` — "Temporary failure resolving"
- Any "Connection refused", "Connection timed out", "Network unreachable"

Don't ask the user "should I check the proxy?" — just do it. The skill is designed
to be proactive and fast. Report what you found and what you changed.

## Network error detection

These patterns in stderr/stdout indicate a network-related failure:

| Category | Patterns |
|----------|----------|
| Connection | `connection refused`, `connection timed out`, `connection reset`, `network unreachable`, `ECONNREFUSED`, `ECONNRESET`, `ETIMEDOUT`, `ENETUNREACH`, `EHOSTUNREACH`, `Cannot assign requested address` |
| DNS | `cannot resolve host`, `could not resolve host`, `Temporary failure in name resolution`, `Name or service not known`, `nodename nor servname provided`, `getaddrinfo` |
| Proxy | `proxy CONNECT`, `407 Proxy Authentication Required`, `bad proxy`, `cannot connect to proxy`, `Tunnel connection failed` |
| curl codes | `curl: (6)` (DNS), `curl: (7)` (connection refused), `curl: (28)` (timeout), `curl: (35)` (SSL), `curl: (56)` (response failure) |
| npm | `npm ERR! network`, `npm ERR! code ECONNRESET`, `npm ERR! errno ECONNRESET`, `npm ERR! network request to https://` |
| git | `fatal: unable to access`, `Failed to connect`, `Could not read from remote repository` |

If you see any of these, **do not give up and report the error** — invoke this
procedure instead.

## Quick reference

```bash
# source proxy functions (always do this first)
source /usr/local/etc/profile.d/proxy.sh

# check current state
[ -n "$HTTP_PROXY" ] && echo "on" || echo "off"

# toggle on
pon

# toggle off
poff

# quick connectivity test (returns 0 if reachable)
curl -s --connect-timeout 5 -o /dev/null https://google.com 2>/dev/null || \
curl -s --connect-timeout 5 -o /dev/null https://1.1.1.1 2>/dev/null || \
curl -s --connect-timeout 5 -o /dev/null https://baidu.com 2>/dev/null
```

## Auto-switch procedure

Follow this exact sequence when a network error is detected:

### Step 1: Confirm it's really a network error

Quickly scan the error output for the patterns above. If it's not network-related
(e.g., 404 Not Found, 403 Forbidden, authentication failure, file not found), don't
toggle the proxy — it won't help.

### Step 2: Check current proxy state

```bash
source /usr/local/etc/profile.d/proxy.sh
if [ -n "$HTTP_PROXY" ]; then echo "proxy=on"; else echo "proxy=off"; fi
```

Note the current state.

### Step 3: Toggle and test

**If proxy is ON:**
1. Run `poff` to turn proxy off
2. Run connectivity test
3. If reachable → tell user "I turned the proxy off and the network is working now. Try your command again."
4. If NOT reachable → restore proxy with `pon`, then go to Step 4

**If proxy is OFF:**
1. Run `pon` to turn proxy on
2. Run connectivity test
3. If reachable → tell user "I turned the proxy on and the network is working now. Try your command again."
4. If NOT reachable → restore with `poff`, then go to Step 4

### Step 4: Both states failed — escalate

If neither proxy state provides connectivity, report to the user:

"I tried both proxy states (on and off), but neither can reach the internet.
Your proxy is currently set to [original state]. Here are some things to check:
- Is your proxy server running? (HTTP: 127.0.0.1:8118, SOCKS5: 127.0.0.1:1080)
- Is your network connection working? Try pinging 8.8.8.8
- Is the target service accessible from your network?
- Do you need a different proxy configuration?"

Also mention: "You can manually switch with `pon` or `poff` if you find a
configuration that works."

## Proxy configuration reference

The user's proxy setup uses these functions (defined in `/usr/local/etc/profile.d/proxy.sh`):

```
pon → HTTP_PROXY=http://127.0.0.1:8118, ALL_PROXY=socks5://127.0.0.1:1080, NO_PROXY=localhost,127.0.0.1,10.0.2.1
poff → unset all proxy environment variables
```

## Important

- Always source the profile script before calling pon/poff, since they're shell
  functions, not standalone binaries.
- After a successful proxy toggle, suggest the user re-run their original command:
  "The network should work now. Try running your command again."
- If the user's original command needed specific arguments or working directory,
  mention that too so they don't have to re-type everything.
- The connectivity test hits multiple targets (google.com, 1.1.1.1, baidu.com) for
  resilience — some may be blocked in certain networks but others usually work.
