#!/usr/bin/env python3
"""Screen capture from the running playtest: python3 tools/shot.py out.png [camX camY camZ lookX lookY lookZ]"""
import base64, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
out, nums = sys.argv[1], [float(a) for a in sys.argv[2:]]
sys.argv = ["drive"]
import drive
args = {"capture_id": "ScreenCapture_1"}
if nums:
    args.update(camera_position=nums[:3], look_at_position=nums[3:6])
for c in drive.call("screen_capture", args)["content"]:
    if c.get("type") == "image":
        open(out, "wb").write(base64.b64decode(c["data"]))
        print("saved", out)
