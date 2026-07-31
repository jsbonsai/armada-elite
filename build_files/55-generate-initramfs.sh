#!/bin/bash
set -euxo pipefail

# Runs after 40-vendor-system-files: the initramfs bundles the armada splash,
# which is not yet installed when the kernel step runs.
KVER="$(ls /usr/lib/modules)"
IMG="/usr/lib/modules/${KVER}/initramfs.img"

# fedora-bootc ships /root -> var/roothome, absent in the build container;
# dracut-install aborts resolving /root without the target.
mkdir -p /var/roothome

dracut \
    --force \
    --no-hostonly \
    --reproducible \
    --kver "${KVER}" \
    --add ostree \
    --add armada-splash \
    "${IMG}" "${KVER}"

# dracut drops modules silently: fail the build rather than ship without.
# Exact match: a substring test lets armada-splash-fb pass for the binary.
contents="$(lsinitrd "${IMG}")"
for required in \
    usr/lib/systemd/system/armada-splash-initrd.service \
    usr/lib/systemd/system/dracut-pre-mount.service.d/armada-splash.conf \
    usr/libexec/armada/armada-splash \
    usr/libexec/armada/armada-splash-fb \
    usr/libexec/armada/device-env \
    usr/share/armada/splash/splash.asp \
    usr/lib/ostree/ostree-prepare-root; do
    if ! awk -v p="${required}" '$NF == p { found=1 } END { exit !found }' <<<"${contents}"; then
        echo "ERROR: ${required} missing from initramfs"
        dracut --list-modules --kver "${KVER}" | grep -i armada || true
        exit 1
    fi
done

echo "initramfs generated for ${KVER} with armada-splash"
