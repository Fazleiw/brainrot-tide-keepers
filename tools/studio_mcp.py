#!/usr/bin/env python3
"""Minimal stdio MCP client for Roblox Studio's bundled StudioMCP binary (Python stdlib only).

  python3 tools/studio_mcp.py list                       # tool names + argument schemas
  python3 tools/studio_mcp.py call <tool> '<json args>'  # call one tool
  python3 tools/studio_mcp.py luau <file.luau> [Server|Client|Edit]   # execute_luau with a file

Env: STUDIO_FILE picks the Studio window whose open file matches; STUDIO_ID pins an exact id;
SAVE=path.png writes an image result there.
"""
import base64, json, os, subprocess, sys, time

BIN = "/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP"


class Client:
    def __init__(self):
        self.proc = subprocess.Popen([BIN], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                     stderr=subprocess.DEVNULL, text=True, bufsize=1)
        self.next_id = 0
        self.request("initialize", {"protocolVersion": "2024-11-05", "capabilities": {},
                                    "clientInfo": {"name": "tide-keepers", "version": "1"}})
        self.send({"jsonrpc": "2.0", "method": "notifications/initialized", "params": {}})

    def send(self, msg):
        self.proc.stdin.write(json.dumps(msg) + "\n")
        self.proc.stdin.flush()

    def request(self, method, params):
        self.next_id += 1
        rid = self.next_id
        self.send({"jsonrpc": "2.0", "id": rid, "method": method, "params": params})
        while True:
            line = self.proc.stdout.readline()
            if not line:
                raise SystemExit("StudioMCP exited")
            try:
                msg = json.loads(line)
            except ValueError:
                continue
            if msg.get("id") == rid:
                if "error" in msg:
                    raise SystemExit("error: " + json.dumps(msg["error"]))
                return msg["result"]

    def call(self, tool, args):
        return self.request("tools/call", {"name": tool, "arguments": args})

    def studios(self):
        res = self.call("list_roblox_studios", {})
        txt = "".join(c.get("text", "") for c in res.get("content", []))
        try:
            return json.loads(txt).get("studios", [])
        except ValueError:
            return []

    def pick_studio(self):
        want_id, want_file = os.environ.get("STUDIO_ID"), os.environ.get("STUDIO_FILE")
        for _ in range(20):  # the bridge needs a moment to discover running Studios
            for st in self.studios():
                if want_id and st.get("id") != want_id:
                    continue
                if want_file and want_file not in str(st.get("file", "")) + str(st.get("name", "")):
                    continue
                return st["id"]
            time.sleep(1)
        raise SystemExit("no matching Studio found")


def show(res):
    for c in res.get("content", []):
        if c.get("type") == "text":
            print(c["text"])
        elif c.get("type") == "image":
            path = os.environ.get("SAVE", "capture.png")
            with open(path, "wb") as f:
                f.write(base64.b64decode(c["data"]))
            print("saved", path)
    if res.get("isError"):
        sys.exit(1)


def main():
    cli = Client()
    tools = {t["name"]: t for t in cli.request("tools/list", {})["tools"]}
    cmd = sys.argv[1]
    if cmd == "list":
        for name, t in tools.items():
            print(name, "::", json.dumps(t.get("inputSchema", {}).get("properties", {}))[:500])
        return
    if cmd == "luau":
        tool = "execute_luau"
        args = {"code": open(sys.argv[2]).read()}
        if len(sys.argv) > 3:
            args["datamodel_type"] = sys.argv[3]
    else:
        tool = sys.argv[2]
        args = json.loads(sys.argv[3]) if len(sys.argv) > 3 else {}
    props = tools.get(tool, {}).get("inputSchema", {}).get("properties", {})
    sid_key = next((k for k in props if "studio" in k.lower() and "id" in k.lower()), None)
    if sid_key and sid_key not in args:
        args[sid_key] = cli.pick_studio()
    show(cli.call(tool, args))


if __name__ == "__main__":
    main()
