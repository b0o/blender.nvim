import sys
import traceback

import bpy

from ..rpc import NvimRpc
from ..utils import in_blender, redraw_all


class UpdateAddonOperator(bpy.types.Operator):
    bl_idname = "dev.update_addon"
    bl_label = "Update Addon"

    if in_blender():
        module_name: bpy.props.StringProperty()  # type: ignore
    else:
        module_name: str

    def execute(self, context):
        try:
            bpy.ops.preferences.addon_disable(module=self.module_name)
        except Exception as e:
            traceback.print_exc()
            NvimRpc.get_instance().send({"type": "disable_failure", "message": str(e)})
            return {"CANCELLED"}

        for name in list(sys.modules.keys()):
            if name.startswith(self.module_name):
                del sys.modules[name]

        try:
            bpy.ops.preferences.addon_enable(module=self.module_name)
        except Exception as e:
            traceback.print_exc()
            NvimRpc.get_instance().send({"type": "enable_failure", "message": str(e)})
            return {"CANCELLED"}

        NvimRpc.get_instance().send({"type": "addon_updated"})

        redraw_all()
        return {"FINISHED"}


@NvimRpc.notification_handler("reload")
def reload_addon_action(data):
    print("reload_addon_action", data)
    for name in data["names"]:
        call_operator(NVIM_OT_UpdateAddon, module_name=name)


classes = (NVIM_OT_UpdateAddon,)


def register():
    for cls in classes:
        bpy.utils.register_class(cls)
