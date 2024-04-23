import sys
from typing import List

import bpy


def fatal(message):
    print()
    print("#" * 80)
    for line in message.splitlines():
        print(">  ", line)
    print("#" * 80)
    print()
    sys.exit(1)


def redraw_all():
    for window in bpy.context.window_manager.windows:
        for area in window.screen.areas:
            area.tag_redraw()


def in_blender():
    return type(bpy.app.version) is tuple


def ensure_installed(pkg_names: List[str | None]):
    missing_pkgs = [pkg for pkg in pkg_names if pkg and not is_importable(pkg)]
    if missing_pkgs:
        return fatal(f"Missing required packages: {', '.join(missing_pkgs)}")


def is_importable(name):
    try:
        __import__(name)
        return True
    except ModuleNotFoundError:
        return False
