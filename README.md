# MediaTek PD Info — module

Installs [MtkPdInfo](https://github.com/soralis0912-dev/packages_apps_MtkPdInfo)
on a ROM that is not ours, as a module for KernelSU or Magisk.

The app reads what the charger offered and which line of it the phone took. On
a ROM built with it the device tree labels the nodes and it needs no root; on
anybody else's it is an ordinary app looking at files labelled for the vendor's
own charging service, and a root shell is the only way in. That is what this
module is for.

Read-only throughout, and it mounts nothing.

## What it does

- installs `MtkPdInfoRoot.apk`, and removes it again when the module is removed
- says at install time what the board publishes, so an empty screen later is
  not a mystery

That is all of it. The qualcomm sibling of this module,
[Qcom-PD-Info-Module](https://github.com/WitAqua-tools/Qcom-PD-Info-Module),
also mounts debugfs, because on that platform the charger's object list can
only be had by putting a command to the UCSI policy manager. MediaTek publishes
the objects in sysfs:

```
/sys/class/tcpc/<port>/caps_info
```

so there is nothing to mount and no `post-fs-data.sh` here. `validate.sh`
fails if one comes back.

## Why root, when nothing needs mounting

The labels. Checked on a handset:

```
u:object_r:sysfs:s0             /sys/class/tcpc/type_c_port0/caps_info
u:object_r:sysfs:s0             /sys/class/typec/port0/
u:object_r:sysfs_batteryinfo:s0 /sys/class/power_supply/usb/real_type
```

An app reaches none of those. The first two a ROM can relabel and grant - that
is what the app's own README describes - and the third it cannot: AOSP's
`domain.te` neverallows `sysfs_batteryinfo` for coredomain, which a platform
app is. So the built-in build shows the objects and the contract, and this one
shows those and the charger's own readings besides.

## What root cannot get

Three things are gone before userspace sees anything, and no privilege brings
them back - MediaTek's port controller decodes each object into four figures on
the way out and the rest does not survive:

- the source flags: whether the charger is mains powered, dual-role, USB
  capable
- the request's own figures: only the object position is published, so the
  negotiated voltage and current are not readable at all. What the charger
  measures is the nearest thing to them
- any supply type the kernel's decoder does not know - an adjustable voltage
  supply, or extended range - which arrives as type 255 with its figures zeroed

The app says so where it matters rather than leaving a silence. The two kernel
changes that would fix the first two are in the app's
[docs/kernel.md](https://github.com/soralis0912-dev/packages_apps_MtkPdInfo/blob/main/docs/kernel.md).

## Installing

Flash the zip in KernelSU or Magisk, reboot, open **USB Power Delivery** and
grant it root when asked.

## Building the zip

The apk is not kept in this repository: it is a build artefact, and the zip is
the only place the two belong together.

```sh
# from a tree that has built the app
./pack.sh                                   # finds MtkPdInfoRoot.apk under out/
./pack.sh path/to/MtkPdInfoRoot.apk         # or hand it one
./validate.sh                               # before tagging
```

`gradle assembleRelease` in the app's own tree is the other way to get an apk,
and is what CI does - see `.github/workflows/ci.yml`.

## CI and releases

Both workflows build the app from its own repository rather than taking an apk
from a release there, so a module release is one action rather than two that
can drift apart. Two things follow from that:

- **`APP_REPO_TOKEN`.** The app repository is private, and `GITHUB_TOKEN` does
  not reach across repositories. Without a token with read access to it there
  is nothing to build, and CI says so rather than failing on a checkout whose
  error does not name the cause.
- **`STORE_FILE`, `STORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`.** The release
  signing key. CI signs with `testkey.jks`, the public AOSP debug key committed
  here, and refuses to publish anything signed with it as a release - a key
  anybody has is a key anybody can sign an update with.

Tag to release. The tag has to match `module.prop`, because `module.prop` is
what the manager shows and `update.json` is what it fetches.

```sh
git tag v0.1.0 && git push origin --tags
```

## Licence

Apache 2.0, and derived from
[Qcom-PD-Info-Module](https://github.com/WitAqua-tools/Qcom-PD-Info-Module)
under the same licence.
