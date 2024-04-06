import sys
from pathlib import Path
from typing import Tuple, cast

import bpy


def startup(
    editor_address: str,
    addons_to_load: Tuple[Tuple[Path, str], ...],
    allow_modify_external_python: bool,
    enable_debugpy: bool,
):
    if cast(Tuple[int, int, int], bpy.app.version) < (2, 80, 34):
        return handle_fatal_error(
            "Unspported Blender version. Please use 2.80.34 or newer."
        )

    from . import installation

    installation.ensure_packages_are_installed(
        ["flask", "requests", "pynvim"], allow_modify_external_python
    )

    if enable_debugpy:
        installation.ensure_packages_are_installed(
            ["debugpy"], allow_modify_external_python
        )

    from . import load_addons

    path_mappings = load_addons.setup_addon_links(addons_to_load)

    from . import communication

    communication.setup(
        address=editor_address,
        path_mappings=path_mappings,
        enable_debugpy=enable_debugpy,
    )

    load_addons.load(addons_to_load)

    from . import operators, ui

    ui.register()
    operators.register()


def handle_fatal_error(message):
    print()
    print("#" * 80)
    for line in message.splitlines():
        print(">  ", line)
    print("#" * 80)
    print()
    sys.exit(1)
