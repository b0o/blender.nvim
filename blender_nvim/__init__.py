import sys
from pathlib import Path
from typing import Tuple

from .environment import blender_path, scripts_folder, version
from .load_addons import load_addons, setup_addon_links
from .utils import ensure_installed, fatal


def ensure_compat():
    if version < (2, 80, 34):
        return fatal("Unspported Blender version. Please use 2.80.34 or newer.")


def startup(
    rpc_socket: str,
    addons_to_load: Tuple[Tuple[Path, str], ...],
    enable_dap: bool,
    task_id: int,
):
    ensure_compat()
    ensure_installed(["pynvim", "debugpy" if enable_dap else None])

    from .rpc import NvimRpc

    path_mappings = setup_addon_links(addons_to_load)

    def on_setup(rpc: NvimRpc):
        rpc.send(
            {
                "type": "setup",
                "python_exe": sys.executable,
                "blender_path": str(blender_path),
                "blender_version": ".".join([str(v) for v in version]),
                "scripts_folder": str(scripts_folder),
                "path_mappings": path_mappings,
                "task_id": task_id,
                "channel_id": rpc.nvim.channel_id,
            }
        )

    rpc = NvimRpc.initialize(rpc_socket, on_setup=on_setup)
    rpc.start()

    load_addons(addons_to_load)

    from . import operators, ui

    ui.register()
    operators.register()

    if enable_dap:
        from .dap import NvimDap

        dap = NvimDap.initialize(rpc)
        dap.start()
