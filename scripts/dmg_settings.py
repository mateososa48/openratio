"""dmgbuild settings for the OpenRatio disk image.

Builds the styled window without driving Finder, so it works the same on a laptop
and on a headless CI runner. Invoked by `make dmg`:

    dmgbuild -s scripts/dmg_settings.py -D app=build/OpenRatio.app -D root=$PWD OpenRatio out.dmg
"""
import os

# dmgbuild exec()s this file, so there is no __file__ here. The Makefile passes
# the repo root in; the fallback covers running dmgbuild by hand from the root.
app = defines.get("app", "build/OpenRatio.app")  # noqa: F821 (dmgbuild injects `defines`)
root = defines.get("root", os.getcwd())          # noqa: F821
app_name = os.path.basename(app)

# ---- contents -------------------------------------------------------------
files = [app]
symlinks = {"Applications": "/Applications"}

# The mounted volume gets the app's own icon.
icon = os.path.join(app, "Contents", "Resources", "AppIcon.icns")

# ---- window ---------------------------------------------------------------
format = "UDZO"          # compressed, read-only
compression_level = 9
size = None              # let dmgbuild size it to the contents

background = os.path.join(root, "Resources", "dmg", "background.tiff")
window_rect = ((260, 200), (660, 420))
default_view = "icon-view"

show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
sidebar_width = 180

arrange_by = None
grid_offset = (0, 0)
grid_spacing = 100
scroll_position = (0, 0)
label_pos = "bottom"
text_size = 12
icon_size = 112

icon_locations = {
    app_name: (170, 190),
    "Applications": (490, 190),
}

# Nothing is hidden, so no license or hidden-file handling is needed.
