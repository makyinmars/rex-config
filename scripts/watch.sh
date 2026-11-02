#!/bin/sh
# Keeps scripts/watch.lua running against the local Rex server, restarting it
# after server restarts. lib/watcher.lua starts this when the configuration
# loads. To stop it:
#
#   kill "$(cat ~/.local/state/rex-config/watch.pid)"
#
# Usage: watch.sh REX_BINARY WATCH_LUA STATE_DIR

rex=$1 script=$2 state=$3
mkdir -p "$state"
pid_file="$state/watch.pid"
log="$state/watch.log"

# One supervisor at a time.
if [ -f "$pid_file" ]; then
  old=$(cat "$pid_file")
  if [ "$old" != "$$" ] && ps -p "$old" -o command= 2>/dev/null | grep -q watch.sh; then
    exit 0
  fi
fi
echo $$ >"$pid_file"
exec >>"$log" 2>&1

# Never start a server: when Rex quits, wait for it to come back.
export REX_AUTOSTART=0

child=
trap '[ -n "$child" ] && kill "$child" 2>/dev/null; rm -f "$pid_file"; exit 0' TERM INT HUP

delay=1
while :; do
  [ "$(wc -c <"$log")" -gt 1048576 ] && : >"$log"
  if "$rex" api call server.status >/dev/null 2>&1; then
    started=$(date +%s)
    echo "$(date '+%F %T') starting watch.lua"
    "$rex" do --all "$script" &
    child=$!
    wait "$child"
    status=$?
    echo "$(date '+%F %T') watch.lua exited with status $status"
    child=
    # Back off when it keeps failing quickly.
    [ $(($(date +%s) - started)) -ge 60 ] && delay=1
  fi
  sleep "$delay"
  [ "$delay" -lt 30 ] && delay=$((delay * 2))
done
