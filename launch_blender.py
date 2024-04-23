import json
import os
import sys
import traceback
from pathlib import Path
from typing import cast

include_dir = Path(__file__).parent
sys.path.append(str(include_dir))

rpc_socket = os.environ.get("BLENDER_NVIM_RPC_SOCKET")
addons_to_load = json.loads(os.environ.get("BLENDER_NVIM_ADDONS_TO_LOAD", "[]"))
enable_debugpy = os.environ.get("BLENDER_NVIM_ENABLE_DAP", "no")
task_id = os.environ.get("BLENDER_NVIM_TASK_ID", "0")

if rpc_socket is not None:
    import blender_nvim

    print("BLENDER_NVIM_RPC_SOCKET     ", rpc_socket)
    print("BLENDER_NVIM_ADDONS_TO_LOAD ", addons_to_load)
    print("BLENDER_NVIM_ENABLE_DAP     ", enable_debugpy)
    print("BLENDER_NVIM_TASK_ID        ", task_id)

    addons_to_load = tuple(
        map(
            lambda x: (Path(x["load_dir"]), cast(str, x["module_name"])),
            addons_to_load,
        )
    )

    try:
        blender_nvim.startup(
            rpc_socket=rpc_socket,
            addons_to_load=addons_to_load,
            enable_dap=enable_debugpy.lower() == "yes",
            task_id=int(task_id),
        )
    except Exception as e:
        if type(e) is not SystemExit:
            traceback.print_exc()
            sys.exit()

else:
    print("BLENDER_NVIM_RPC_SOCKET is not set")
