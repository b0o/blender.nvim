import json
import os
import sys
import traceback
from pathlib import Path

include_dir = Path(__file__).parent
sys.path.append(str(include_dir))

print(__file__)

if os.environ.get("EDITOR_ADDR") is not None:

    import blender_nvim

    editor_addr = os.environ.get("EDITOR_ADDR")
    addons_to_load = json.loads(os.environ.get("ADDONS_TO_LOAD", "[]"))
    allow_modify_external_python = os.environ.get("ALLOW_MODIFY_EXTERNAL_PYTHON", "no")

    print("EDITOR_ADDR", editor_addr)
    print("ADDONS_TO_LOAD", addons_to_load)
    print("ALLOW_MODIFY_EXTERNAL_PYTHON", allow_modify_external_python)

    try:
        blender_nvim.startup(
            editor_address=editor_addr,
            addons_to_load=tuple(
                map(
                    lambda x: (Path(x["load_dir"]), x["module_name"]),
                    addons_to_load,
                )
            ),
            allow_modify_external_python=allow_modify_external_python == "yes",
        )
    except Exception as e:
        if type(e) is not SystemExit:
            traceback.print_exc()
            sys.exit()
