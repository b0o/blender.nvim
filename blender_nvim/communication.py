import os
import random
import sys
import threading
import time
from functools import partial
from typing import List, Optional

import debugpy
import flask
import pynvim
from pynvim.msgpack_rpc.event_loop import base as pynvim_event_loop_base

from .environment import blender_path, scripts_folder
from .utils import run_in_main_thread

# override default interrupt handler to avoid error when running in Blender
# in background mode
# SEE: https://github.com/neovim/pynvim/issues/264
pynvim_event_loop_base.default_int_handler = lambda _: None

EDITOR_ADDRESS: str
OWN_SERVER_PORT: int
DEBUGPY_PORT: int


def setup(address, path_mappings):
    global EDITOR_ADDRESS, OWN_SERVER_PORT, DEBUGPY_PORT, nvim
    EDITOR_ADDRESS = address

    OWN_SERVER_PORT = start_own_server()
    DEBUGPY_PORT = start_debug_server()

    print(f"Attaching to Nvim at {address}")
    nvim = pynvim.attach("socket", path=address)
    send_connection_information(path_mappings)

    print("Waiting for debug client.")
    debugpy.wait_for_client()
    print("Debug client attached.")


def start_own_server():
    port: List[Optional[int]] = [None]

    def server_thread_function():
        while True:
            try:
                port[0] = get_random_port()
                server.run(debug=True, port=port[0], use_reloader=False)
            except OSError:
                pass

    thread = threading.Thread(target=server_thread_function)
    thread.daemon = True
    thread.start()

    while port[0] is None:
        time.sleep(0.01)

    return port[0]


def start_debug_server():
    while True:
        port = get_random_port()
        try:
            # enable completion
            debugpy.configure()
            debugpy.listen(("localhost", port))
            break
        except OSError:
            pass
    return port


# Server
#########################################

server = flask.Flask("Blender Server")
post_handlers = {}


@server.route("/", methods=["POST"])
def handle_post():
    data = flask.request.get_json()
    print("Got POST:", data)

    if data["type"] in post_handlers:
        return post_handlers[data["type"]](data)

    return "OK"


@server.route("/", methods=["GET"])
def handle_get():
    flask.request
    data = flask.request.get_json()
    print("Got GET:", data)

    if data["type"] == "ping":
        pass
    return "OK"


def register_post_handler(type, handler):
    assert type not in post_handlers
    post_handlers[type] = handler


def register_post_action(type, handler):
    def request_handler_wrapper(data):
        run_in_main_thread(partial(handler, data))
        return "OK"

    register_post_handler(type, request_handler_wrapper)


# Sending Data
###############################


def send_connection_information(path_mappings):
    send_rpc_msg(
        {
            "type": "setup",
            "blender_port": OWN_SERVER_PORT,
            "debugpy_port": DEBUGPY_PORT,
            "python_exe": sys.executable,
            "blender_path": str(blender_path),
            "scripts_folder": str(scripts_folder),
            "addon_path_mappings": path_mappings,
            "task_id": os.environ.get("BLENDER_NVIM_TASK_ID", "0"),
        }
    )


def send_rpc_msg(data):
    print("Sending:", data)
    nvim.exec_lua('require("blender.rpc").handle(...)', data)
    # TODO: Handle errors


# Utils
###############################


def get_random_port():
    return random.randint(2000, 10000)


def get_blender_port():
    return OWN_SERVER_PORT


def get_debugpy_port():
    return DEBUGPY_PORT


def get_editor_address():
    return EDITOR_ADDRESS
