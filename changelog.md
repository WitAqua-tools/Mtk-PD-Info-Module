## v0.1.0

- First build. Installs the USB Power Delivery viewer for MediaTek boards,
  which reads the port controller's own class at /sys/class/tcpc. Nothing is
  mounted: unlike the qualcomm sibling of this module there is no debugfs
  interface to reach for, only labels an app is not granted.
