import queue
import threading
import traceback
from typing import Any, Callable, Dict, List, Literal, Optional

import bpy
import pynvim


class NvimRpc:
    _instance: Optional["NvimRpc"] = None

    _request_handlers: Dict[str, Callable[["NvimRpc", List[Any]], None]] = {}
    _notification_handlers: Dict[str, Callable[["NvimRpc", List[Any]], None]] = {}

    # --- Class Methods --- #

    @classmethod
    def initialize(
        cls, sock: str, on_setup: Optional[Callable[["NvimRpc"], None]] = None
    ):
        if cls._instance is not None:
            raise ValueError("NvimRpc instance is already initialized")
        cls._instance = cls(sock, on_setup)
        return cls._instance

    @classmethod
    def get_instance(cls):
        if cls._instance is None:
            raise ValueError("NvimRpc instance is not initialized")
        return cls._instance

    @classmethod
    def get_instance_safe(cls):
        return cls._instance

    @classmethod
    def _register_handler(
        cls,
        kind: Literal["request", "notification"],
        name: str,
        handler: Callable[[List[Any]], None],
        main_thread: bool = True,
    ):
        def wrapper(self, args):
            if main_thread:
                self.schedule(lambda: handler(*args))
            else:
                handler(*args)

        registry = (
            cls._request_handlers if kind == "request" else cls._notification_handlers
        )
        registry[name] = wrapper

    @classmethod
    def request_handler(cls, name: str, main_thread: bool = True):
        def decorator(handler: Callable[[List[Any]], None]):
            cls._register_handler("request", name, handler, main_thread)
            return handler

        return decorator

    @classmethod
    def notification_handler(cls, name: str, main_thread: bool = True):
        def decorator(handler: Callable[[List[Any]], None]):
            cls._register_handler("notification", name, handler, main_thread)
            return handler

        return decorator

    # --- Instance Methods --- #

    _sock: str
    nvim: pynvim.Nvim
    _main_thread: threading.Thread
    _session_thread: Optional[threading.Thread]
    _execution_queue: queue.Queue
    _on_setup_cb: Optional[Callable[["NvimRpc"], None]]

    def __init__(
        self, sock: str, on_setup: Optional[Callable[["NvimRpc"], None]] = None
    ):
        if self._instance is not None:
            raise ValueError("NvimRpc instance is already initialized")
        self._sock = sock
        self.nvim = pynvim.attach("socket", path=sock)
        self._main_thread = threading.current_thread()
        self._session_thread = None
        self._execution_queue = queue.Queue()
        self._on_setup_cb = on_setup

    def schedule(self, func: Callable[[], None]):
        self._execution_queue.put(func)

    def _on_request(self, name: str, args: List[Any]):
        print("RPC request:", name, args)
        if name not in self._request_handlers:
            print("No handler for request:", name)
            return
        self._request_handlers[name](self, args)

    def _on_notification(self, name: str, args: list):
        print("RPC notification:", name, args)
        if name not in self._notification_handlers:
            print("No handler for notification:", name)
            return
        self._notification_handlers[name](self, args)

    def _on_setup(self):
        print("RPC setup")
        if self._on_setup_cb is not None:
            self._on_setup_cb(self)

    def _start_session(self):
        def run():
            if self._session_thread is None:
                return
            self.nvim._session.run(
                request_cb=self._on_request,
                notification_cb=self._on_notification,
                setup_cb=self._on_setup,
            )

        self._session_thread = threading.Thread(target=run)
        self._session_thread.daemon = True
        self._session_thread.start()

    def _start_executor(self):
        def executor():
            while not self._execution_queue.empty():
                func = self._execution_queue.get()
                try:
                    func()
                except:  # noqa: E722
                    traceback.print_exc()
            return 0.1

        bpy.app.timers.register(executor, persistent=True)

    def start(self):
        self._start_executor()
        self._start_session()

    def send(self, data):
        if threading.current_thread() != self._session_thread:
            self.nvim._session.threadsafe_call(lambda: self.send(data))
            return
        print("RPC send:", data)
        self.nvim.exec_lua('require("blender.rpc").handle(...)', data)
        # TODO: Handle errors
