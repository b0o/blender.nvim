from typing import Optional

from .rpc import NvimRpc


class NvimDap:
    _instance: Optional["NvimDap"] = None

    # --- Class Methods --- #

    @classmethod
    def initialize(cls, rpc: NvimRpc):
        if cls._instance is not None:
            raise ValueError("NvimDap instance is already initialized")
        cls._instance = cls(rpc)
        return cls._instance

    @classmethod
    def get_instance(cls):
        if cls._instance is None:
            raise ValueError("NvimDap instance is not initialized")
        return cls._instance

    @classmethod
    def get_instance_safe(cls):
        return cls._instance

    # --- Instance Methods --- #
    rpc: NvimRpc
    started: bool = False
    host: Optional[str]
    port: Optional[int]

    def __init__(self, rpc: NvimRpc):
        self.rpc = rpc

    def start(self):
        import debugpy

        debugpy.configure()
        self.host, self.port = debugpy.listen(("localhost", 0))
        print(f"Debugpy listening on {self.host}:{self.port}")
        self.rpc.send(
            {
                "type": "setup_debugpy",
                "host": self.host,
                "port": self.port,
            }
        )
        print("Waiting for debug client.")
        debugpy.wait_for_client()
        print("Debug client attached.")
