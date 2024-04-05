import sys
import traceback

import bpy
from bpy.props import *

from ..communication import register_post_action, send_rpc_msg
from ..utils import redraw_all


class UpdateAddonOperator(bpy.types.Operator):
    bl_idname = "dev.update_addon"
    bl_label = "Update Addon"

    module_name: StringProperty()

    def execute(self, context):
        try:
            bpy.ops.preferences.addon_disable(module=self.module_name)
        except:
            traceback.print_exc()
            send_rpc_msg({"type": "disableFailure"})
            return {"CANCELLED"}

        for name in list(sys.modules.keys()):
            if name.startswith(self.module_name):
                del sys.modules[name]

        try:
            bpy.ops.preferences.addon_enable(module=self.module_name)
        except:
            traceback.print_exc()
            send_rpc_msg({"type": "enableFailure"})
            return {"CANCELLED"}

        send_rpc_msg({"type": "addonUpdated"})

        redraw_all()
        return {"FINISHED"}


def reload_addon_action(data):
    for name in data["names"]:
        bpy.ops.dev.update_addon(module_name=name)


def register():
    bpy.utils.register_class(UpdateAddonOperator)
    register_post_action("reload", reload_addon_action)
