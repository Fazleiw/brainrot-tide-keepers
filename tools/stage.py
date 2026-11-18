#!/usr/bin/env python3
"""Plays a fresh playtest through buy -> carry -> place for every slot of Plot 1, waiting out each tide surge
on the high ground so no trip is caught in the water. Uses Studio-only test money to skip the grind.

  python3 tools/stage.py [grant]
"""
import os, sys, time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.argv, args = ["drive"], sys.argv[1:]
import drive

TIDE = """return (workspace:GetAttribute("TidePhase") or "?") .. " " .. tostring(math.floor((workspace:GetAttribute("TidePhaseEndsAt") or 0) - workspace:GetServerTimeNow()))"""


def safe_seconds():
    phase, left = drive.luau(TIDE).split()
    return int(left) + 10 if phase == "Calm" else -1


def wait_for_safe_window(need=24):
    while safe_seconds() < need:
        time.sleep(2)


def trip(rarity, slot):
    wait_for_safe_window()
    drive.walk("game.Workspace.Stall.Pedestals." + rarity)
    drive.hold("E", 900)
    drive.walk(f"game.Workspace.Plots.Plot1.Slots.Slot{slot}")
    drive.hold("E", 400)
    print(rarity, slot, "->", drive.luau(drive.STATUS))


drive.luau(f'workspace:SetAttribute("StudioGrantMoney", {int(args[0]) if args else 60000}) return 1')
# Tall keepers in the front row, a short one in the back-centre slot right under the base sign.
for rarity, slot in [("Legendary", 4), ("Legendary", 6), ("Epic", 5), ("Rare", 1), ("Rare", 3), ("Common", 2)]:
    trip(rarity, slot)
