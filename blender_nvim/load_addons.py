import os
import sys
import traceback

import bpy

from .environment import addon_directories, user_addon_directory
from .rpc import NvimRpc


def setup_addon_links(addons_to_load):
    if not os.path.exists(user_addon_directory):
        os.makedirs(user_addon_directory)

    if str(user_addon_directory) not in sys.path:
        sys.path.append(str(user_addon_directory))

    path_mappings = []

    for source_path, module_name in addons_to_load:
        if is_in_any_addon_directory(source_path):
            load_path = source_path
        else:
            load_path = os.path.join(user_addon_directory, module_name)
            create_link_in_user_addon_directory(source_path, load_path)

        path_mappings.append({"src": str(source_path), "load": str(load_path)})

    return path_mappings


def load_addons(addons_to_load):
    for source_path, module_name in addons_to_load:
        try:
            bpy.ops.preferences.addon_enable(module=module_name)
        except:  # noqa: E722
            traceback.print_exc()
            NvimRpc.get_instance().send(
                {"type": "enable_failure", "message": traceback.format_exc()}
            )


def create_link_in_user_addon_directory(directory, link_path):
    if os.path.exists(link_path):
        os.remove(link_path)

    if sys.platform == "win32":
        import _winapi

        _winapi.CreateJunction(str(directory), str(link_path))
    else:
        os.symlink(str(directory), str(link_path), target_is_directory=True)


def is_in_any_addon_directory(module_path):
    for path in addon_directories:
        if path == module_path.parent:
            return True
    return False
