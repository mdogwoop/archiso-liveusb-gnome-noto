#!/usr/bin/env bash
set -euo pipefail

profile_dir=/profile
build_dir=/build
out_dir="$build_dir/out"
log_dir="$build_dir/logs"
mkdir -p "$out_dir" "$log_dir"

# Refresh the keyring before the full rolling-release upgrade.
pacman -Sy --needed --noconfirm archlinux-keyring
pacman -Syu --needed --noconfirm archiso

bash -n "$profile_dir/profiledef.sh"
mapfile -t packages < <(sed 's/#.*//; /^[[:space:]]*$/d' "$profile_dir/packages.x86_64")
# Resolve package names, providers and groups before constructing the rootfs.
pacman -Sp --noconfirm --print-format '%n %v' "${packages[@]}" \
    > "$log_dir/resolved-packages.txt"
printf 'Source commit: %s\nBuild time (UTC): %s\n' \
    "${SOURCE_COMMIT:-unknown}" "$(date -u +%FT%TZ)" > "$log_dir/build-info.txt"
pacman -Q >> "$log_dir/build-info.txt"

mkarchiso -v -w "$build_dir/work" -o "$out_dir" "$profile_dir"

shopt -s nullglob
isos=("$out_dir"/*.iso)
if (( ${#isos[@]} != 1 )); then
    echo "Expected one ISO, found ${#isos[@]}" >&2
    exit 1
fi
iso="${isos[0]}"

# Inspect the actual ISO, including both BIOS and UEFI boot entries.
xorriso -indev "$iso" -report_el_torito plain -report_system_area plain \
    2>&1 | tee "$log_dir/iso-boot-layout.txt"
grep -q 'BIOS' "$log_dir/iso-boot-layout.txt"
grep -q 'UEFI' "$log_dir/iso-boot-layout.txt"
inspect_dir="$build_dir/inspect"
mkdir -p "$inspect_dir"
xorriso -osirrox on -indev "$iso" \
    -extract /arch/boot/x86_64 "$inspect_dir/boot" \
    -extract /boot/syslinux "$inspect_dir/syslinux" \
    -extract /loader "$inspect_dir/loader" \
    -extract /arch/pkglist.x86_64.txt "$log_dir/iso-packages.txt"
test -s "$inspect_dir/boot/vmlinuz-linux"
test -s "$inspect_dir/boot/initramfs-linux.img"
if grep -RE 'intel-ucode\.img|amd-ucode\.img|%ARCHISO_|%INSTALL_DIR%' \
    "$inspect_dir/syslinux"/*.cfg "$inspect_dir/loader/entries"/*.conf; then
    echo 'Stale boot configuration found in the ISO.' >&2
    exit 1
fi
bsdtar -tf "$inspect_dir/boot/initramfs-linux.img" \
    > "$log_dir/initramfs-contents.txt"
grep -q 'kernel/x86/microcode/' "$log_dir/initramfs-contents.txt"

(cd "$out_dir" && sha256sum -- *.iso > SHA256SUMS && sha256sum -c SHA256SUMS)
du -h "$iso"
