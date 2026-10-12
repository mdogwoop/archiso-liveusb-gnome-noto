Arch Linux Live USB with Gnome
===========================

![archiso-liveusb-gnome](https://github.com/jorisdrenth/archiso-liveusb-gnome/blob/main/archiso-liveusb-gnome.png?raw=true)

About
-----
This repo is based on the default archiso releng profile, which is used to create the monthly installation ISO's. The goal is to create a Live USB disk with a GUI so you can read the wiki while installing Arch Linux on your PC.

The following has been added:
- Gnome
- Gnome Console
- Firefox
- Nautilus
- nano
- xorg-drivers
- Gnome Text Editor
- eog
- some configs for autologin and darkmode
- [a wallpaper](airootfs/usr/local/share/backgrounds/wallpaper.png)

Usage
-----
On Arch Linux, install `archiso`, clone this repo, and create the ISO from its root:
```
sudo pacman -Syu archiso
sudo mkarchiso -v -w ./work -o ./out .
```
Add more packages to [packages.x86_64](packages.x86_64) if needed.

GitHub Actions
--------------
The **Build Arch Linux GNOME ISO** workflow builds on pushes that change the
profile or build scripts on `main` and the initial `codex/github-actions-iso`
integration branch. Once the workflow is on the default branch, it can also be
started from **Actions → Build Arch Linux GNOME ISO → Run workflow**.

The build runs in the official `archlinux:base` Docker image with the privileges
needed by Archiso. It upgrades Arch packages, resolves the profile's package
list, builds the ISO, inspects BIOS/UEFI boot entries and embedded microcode,
and generates SHA256 checksums. GNOME and Noto fonts remain in the profile.

Download the ISO artifact and verify it with `sha256sum -c SHA256SUMS` after
extracting it. A separate artifact contains the build log, resolved package
versions, source commit, and container digest. Both artifacts are kept for
7 days. Builds use the current Arch repositories; identical source commits
can therefore produce different package versions on different dates.

The compatibility update was checked against Archiso 91 and the current
official `core`/`extra` package databases. It updates boot mode names, embeds
microcode in the initramfs, uses the Broadcom DKMS replacement with kernel
headers, and updates cloud-init service names and the Memtest86+ boot path.
CI's image inspection does not replace a BIOS/UEFI boot test or GNOME desktop
test in a VM or on hardware.
