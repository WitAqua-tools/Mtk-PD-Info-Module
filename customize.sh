#
# Copyright (C) 2026 The WitAqua Project
# SPDX-License-Identifier: Apache-2.0
#

ui_print "- MediaTek PD Info"

# The app is installed rather than overlaid into /system: it is an ordinary
# application, signed with our own key, and has no business on the system
# image. A module that only carried an apk would install and do nothing.
APK=$MODPATH/MtkPdInfoRoot.apk
if [ ! -f "$APK" ]; then
  abort "! MtkPdInfoRoot.apk is missing from the module"
fi

ui_print "- Installing the viewer"
if pm install -r -i com.android.vending "$APK" >/dev/null 2>&1; then
  ui_print "  installed"
else
  # A signature clash with an existing install is the one failure worth
  # naming, because uninstalling first is the only way past it.
  ui_print "  ! could not install. If an older build is present and was signed"
  ui_print "    with a different key, uninstall it and flash this again."
fi

# Say up front what this board can give. Unlike the qualcomm sibling of this
# module there is nothing to mount and nothing that root cannot reach - either
# MediaTek's port controller is there, in which case the whole screen works, or
# this is not a MediaTek board and the app is the wrong one.
if [ -n "$(ls /sys/class/tcpc/*/caps_info 2>/dev/null)" ]; then
  ui_print "- MediaTek's port controller is present. The charger's object list,"
  ui_print "  what this port asks for and which object is in use all come from"
  ui_print "  it, and root is all that is needed to read them."
elif [ -d /sys/class/tcpc ]; then
  ui_print "! /sys/class/tcpc is there with no port in it, which is a board"
  ui_print "  whose port controller did not probe. Nothing to read yet."
else
  ui_print "! No /sys/class/tcpc on this kernel, so there is no object list to"
  ui_print "  read and root does not change that. The viewer will show what the"
  ui_print "  type-C class and the charger say, and name what is missing."
  if [ -d /sys/class/usbpd ] || [ -n "$(ls -d /sys/class/usb_power_delivery/*/ 2>/dev/null)" ]; then
    ui_print "  This looks like a qualcomm board; Qcom PD Info is the one for it."
  fi
fi

ui_print "- Reboot, then open \"USB Power Delivery\" and grant it root."

set_perm_recursive "$MODPATH" 0 0 0755 0644
