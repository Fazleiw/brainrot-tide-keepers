#!/bin/sh
# Rebuilds the place, reopens build/playtest.rbxl in its own Studio window (leaving the game.rbxl window alone),
# closes the docked panels, sizes the window for a 16:9 (1800x1012) viewport and starts a play test.
# The window is opened in the background and parked off-screen so it never takes the operator's screen; it only
# ever touches the window named playtest.rbxl (never Publish Experience or BrainrotTideKeepers-FINAL).
cd "$(dirname "$0")/.."
python3 tools/build_world.py && rojo build default.project.json --output game.rbxl || exit 1
pid=$(pgrep -f "localPlaceFile .*build/playtest.rbxl" | head -1)
[ -n "$pid" ] && kill -9 "$pid" && sleep 2
rm -f build/playtest.rbxl.lock
cp game.rbxl build/playtest.rbxl
open -g -a /Applications/RobloxStudio.app build/playtest.rbxl  # -g: do not activate Studio
sleep 8
pid=$(pgrep -f "localPlaceFile .*build/playtest.rbxl" | head -1)
ui() { osascript -e "tell application \"System Events\" to tell (first process whose unix id is $pid) to $1" 2>/dev/null; }
for i in $(seq 1 40); do
  ui "get name of every window" | grep -q playtest && break
  sleep 1
done
sleep 4
W='(first window whose name contains "playtest.rbxl")'  # not "window 1": a Publish dialog can sit in front
for i in 1 2 3 4 5 6 7 8; do
  ui "click (first button of $W whose description is \"Close\")" >/dev/null || break
done
ui "set position of $W to {-3000, 200}"
ui "set size of $W to {906, 800}"
STUDIO_FILE=playtest python3 tools/studio_mcp.py call start_stop_play '{"is_start":true}'
