from . import addon_update, script_runner, stop_blender

modules = (
    addon_update,
    script_runner,
    stop_blender,
)


def register():
    for module in modules:
        module.register()
