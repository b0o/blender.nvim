import sys
from typing import Type, TypeVar, List

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


TOperator = TypeVar("TOperator", bound=bpy.types.Operator)


def call_operator(operator: Type[TOperator], *args, **kwargs):
    idname = operator.bl_idname.split(".")
    op = bpy.ops
    for name in idname:
        if not hasattr(op, name):
            raise ValueError(f"Operator not found: {operator.bl_idname}")
        op = getattr(op, name)
    if not callable(op):
        raise ValueError(f"Operator not found: {operator.bl_idname}")
    return op(*args, **kwargs)
