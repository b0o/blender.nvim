import json
import os
import sys
import traceback
from pathlib import Path
from typing import cast

from importlib.util import find_spec

include_dir = Path(__file__).parent
sys.path.append(str(include_dir))


def log(level, message):
    print(f"[Blender.nvim] {level}: {message}")


def append_venv_path(virtual_env: str):
    venv_dir = Path(virtual_env)
    if not venv_dir.exists():
        log("WARN", f"Virtual environment does not exist: {venv_dir}")
        return
    lib_dir = venv_dir / "lib"
    if not lib_dir.exists():
        log("WARN", f"Virtual environment does not have lib directory: {lib_dir}")
        return
    python_ver = f"{sys.version_info.major}.{sys.version_info.minor}"
    python_dir = lib_dir / f"python{python_ver}"
    if not python_dir.exists():
        log(
            "WARN",
            f"Virtual environment does not have matching python directory: {python_dir}",
        )
        log(
            "WARN",
            f"Ensure that the virtual environment was created with the same Python version as Blender ({python_ver})",
        )
        return
    site_packages_dir = python_dir / "site-packages"
    if not site_packages_dir.exists():
        log(
            "WARN",
            f"Virtual environment does not have site-packages directory: {site_packages_dir}",
        )
        return
    for path in sys.path:
        path = Path(path)
        if not path.exists():
            continue
        if path.samefile(site_packages_dir):
            log("INFO", f"Virtual environment already in path: {path}")
            return
    log("INFO", f"Using virtual environment: {venv_dir}")
    sys.path.append(str(site_packages_dir))


rpc_socket = os.environ.get("BLENDER_NVIM_RPC_SOCKET")
addons_to_load = json.loads(os.environ.get("BLENDER_NVIM_ADDONS_TO_LOAD", "[]"))
enable_debugpy = os.environ.get("BLENDER_NVIM_ENABLE_DAP", "no")
task_id = os.environ.get("BLENDER_NVIM_TASK_ID", "0")
virtual_env = os.environ.get("VIRTUAL_ENV")

if virtual_env is not None:
    append_venv_path(virtual_env)

if rpc_socket is not None:
    if find_spec("pynvim") is None:
        log(
            "ERROR",
            "Could not find pynvim module. Ensure you have activated your virtual environment before starting Neovim, or install the Python dependencies globally.",
        )
        sys.exit(1)

    import blender_nvim

    log("INFO", f"RPC socket: {rpc_socket}")
    log("INFO", f"Addons to load: {addons_to_load}")
    log("INFO", f"Enable debugpy: {enable_debugpy}")
    log("INFO", f"Task ID: {task_id}")

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
    log("WARN", "BLENDER_NVIM_RPC_SOCKET is not set, not starting Blender.nvim")
