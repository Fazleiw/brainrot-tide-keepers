#!/bin/sh
# Rebuilds the place, reopens build/playtest.rbxl in its own Studio window (leaving the game.rbxl window alone),
# closes the docked panels, sizes the window for a ~16:9 viewport and starts a play test.
cd "$(dirname "$0")/.."
python3 tools/build_world.py && rojo build default.project.json --output game.rbxl || exit 1
pid=$(pgrep -f "localPlaceFile .*build/playtest.rbxl" | head -1)
[ -n "$pid" ] && kill -9 "$pid" && sleep 2
rm -f build/playtest.rbxl.lock
cp game.rbxl build/playtest.rbxl
open -a /Applications/RobloxStudio.app build/playtest.rbxl
sleep 8
pid=$(pgrep -f "localPlaceFile .*build/playtest.rbxl" | head -1)
ui() { osascript -e "tell application \"System Events\" to tell (first process whose unix id is $pid) to $1" 2>/dev/null; }
for i in $(seq 1 40); do
  ui "get name of window 1" | grep -q playtest && break
  sleep 1
done
sleep 4
for i in 1 2 3 4 5 6 7 8; do
  ui "click (first button of window 1 whose description is \"Close\")" >/dev/null || break
done
ui "set position of window 1 to {0, 25}"
ui "set size of window 1 to {1060, 930}"
STUDIO_FILE=playtest python3 tools/studio_mcp.py call start_stop_play '{"is_start":true}'
