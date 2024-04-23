import bpy

from .dap import NvimDap
from .rpc import NvimRpc


class PT_NVIM_Info(bpy.types.Panel):
    bl_idname = "DEV_PT_panel"
    bl_label = "Blender.nvim"
    bl_space_type = "VIEW_3D"
    bl_region_type = "UI"
    bl_category = "Dev"

    def draw(self, context):
        layout = self.layout
        rpc = NvimRpc.get_instance_safe()
        dap = NvimDap.get_instance_safe()

        layout.row().label(text="RPC Socket:")
        layout.row().box().label(text=rpc._sock if rpc else "N/A")

        layout.row().label(text="RPC Channel:")
        layout.row().box().label(text=str(rpc.nvim.channel_id) if rpc else "N/A")

        layout.row().label(text="Debugpy Server:")
        layout.row().box().label(text=f"{dap.host}:{dap.port}" if dap else "N/A")


classes = (PT_NVIM_Info,)


def register():
    for cls in classes:
        bpy.utils.register_class(cls)
