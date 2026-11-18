#!/usr/bin/env python3
"""Drives a running playtest through Studio MCP: walk, hold E, query the server, capture the screen.

  python3 tools/drive.py buy Legendary          # walk to a stall pedestal and hold E
  python3 tools/drive.py place 1 5              # walk to Plot1 Slot5 and press E
  python3 tools/drive.py goto x y z
  python3 tools/drive.py key E 2500             # hold a key for ms
  python3 tools/drive.py server '<luau>'        # run Luau on the server, print the result
  python3 tools/drive.py client '<luau>'
  python3 tools/drive.py grant 30000            # Studio-only test money (see init.server.luau)
  python3 tools/drive.py status
  python3 tools/drive.py cap build/x.png
"""
import base64, os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import studio_mcp

os.environ.setdefault("STUDIO_FILE", "playtest")
cli = studio_mcp.Client()
sid = cli.pick_studio()


def call(tool, args):
    args = dict(args, studio_id=sid)
    res = cli.call(tool, args)
    return res


def text(res):
    return "".join(c.get("text", "") for c in res.get("content", []))


def luau(code, dm="Server"):
    return text(call("execute_luau", {"datamodel_type": dm, "code": code}))


def walk(path=None, xyz=None):
    args = {"datamodel_type": "Client", "speed_multiplier": 2.5}
    if path:
        args["instance_path"] = path
    else:
        args.update(x=xyz[0], y=xyz[1], z=xyz[2])
    return text(call("character_navigation", args))


def hold(key, ms):
    return text(call("user_keyboard_input", {"datamodel_type": "Client", "actions": [
        {"action": "keyDown", "key_code": key}, {"action": "wait", "wait_time_ms": ms}, {"action": "keyUp", "key_code": key}]}))


STATUS = """local p=game.Players:GetPlayers()[1]
return string.format("money %s income %s carrying %s | tide %s ends in %.0fs | pos %s",
 tostring(p:GetAttribute("Money")), tostring(p:GetAttribute("Income")), tostring(p:GetAttribute("CarryingId")),
 tostring(workspace:GetAttribute("TidePhase")), (workspace:GetAttribute("TidePhaseEndsAt") or 0)-workspace:GetServerTimeNow(),
 tostring(p.Character and p.Character:GetPivot().Position))"""


def main():
    cmd, args = sys.argv[1], sys.argv[2:]
    if cmd == "buy":
        print(walk("game.Workspace.Stall.Pedestals." + args[0]))
        print(hold("E", 900))
    elif cmd == "place":
        print(walk(f"game.Workspace.Plots.Plot{args[0]}.Slots.Slot{args[1]}"))
        print(hold("E", 400))
    elif cmd == "goto":
        print(walk(xyz=[float(a) for a in args]))
    elif cmd == "key":
        print(hold(args[0], int(args[1])))
    elif cmd == "server":
        print(luau(args[0]))
    elif cmd == "client":
        print(luau(args[0], "Client"))
    elif cmd == "grant":
        print(luau(f'workspace:SetAttribute("StudioGrantMoney", {int(args[0])}) return "ok"'))
    elif cmd == "cap":
        res = call("screen_capture", {"capture_id": "ScreenCapture_1"})
        for c in res.get("content", []):
            if c.get("type") == "image":
                open(args[0], "wb").write(base64.b64decode(c["data"]))
                print("saved", args[0])
    if cmd != "cap":
        print(luau(STATUS))


if __name__ == "__main__":
    main()
