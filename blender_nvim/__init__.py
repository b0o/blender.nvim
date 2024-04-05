import sys
from typing import Tuple, cast

import bpy


def startup(editor_address, addons_to_load, allow_modify_external_python):
    if cast(Tuple[int, int, int], bpy.app.version) < (2, 80, 34):
        return handle_fatal_error(
            "Unspported Blender version. Please use 2.80.34 or newer."
        )

    from . import installation

    installation.ensure_packages_are_installed(
        ["debugpy", "flask", "requests", "pynvim"], allow_modify_external_python
    )

    from . import load_addons

    path_mappings = load_addons.setup_addon_links(addons_to_load)

    from . import communication

    communication.setup(editor_address, path_mappings)

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
