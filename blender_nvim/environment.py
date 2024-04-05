import platform
import sys
from pathlib import Path
from typing import List, Tuple, cast

import addon_utils
import bpy

python_path = Path(sys.executable)
blender_path = Path(cast(str, bpy.app.binary_path))
blender_directory = blender_path.parent

# Test for MacOS app bundles
if platform.system() == "Darwin":
    use_own_python = blender_directory.parent in python_path.parents
else:
    use_own_python = blender_directory in python_path.parents

version = cast(Tuple[int, int, int], bpy.app.version)
scripts_folder = blender_path.parent / f"{version[0]}.{version[1]}" / "scripts"
user_addon_directory = Path(bpy.utils.user_resource("SCRIPTS", path="addons"))
addon_directories = tuple(map(Path, cast(List[str], addon_utils.paths())))
