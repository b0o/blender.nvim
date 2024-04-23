import bpy

from ..rpc import NvimRpc


@NvimRpc.notification_handler("stop")
def stop_action(data):
    bpy.ops.wm.quit_blender()


def register():
    pass
